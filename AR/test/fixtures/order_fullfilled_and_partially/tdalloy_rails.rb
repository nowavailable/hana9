# alloy上で仕様記述したそのExamples出力から、テストフィクスチャを生成する。
# rails console 上で実行する。

require 'kconv'
require 'active_support/core_ext/hash/conversions'

xml = open("/home/appuser/Dropbox/hana9/0.cnf.xml").read.toutf8
hash = Hash.from_xml(xml)

# Boundaryの様子を抽出
boundaries = {}
hash["alloy"]["instance"]["field"].each {|f|
  next if !f["tuple"]
  next if !f["tuple"][0].is_a? Hash
  next if !f["tuple"][0]["atom"][0]["label"].match(/\/Boundary/)
  #pp "Boundary"
  f["tuple"].each {|t|
    if t.is_a? Hash and t["atom"][0]["label"].match(/\/Boundary/)
      #p "  " + t["atom"][0]["label"].match(/([^\/]+)$/)[1] + " -> " + t["atom"][1]["label"]
      boundaries[t["atom"][0]["label"].match(/([^\/]+)$/)[1]] = t["atom"][1]["label"]
    end
  }
}; nil
boundary_formulas = {}
# 参照されているBoundaryをリストアップ
hash["alloy"]["instance"]["field"].each {|f|
  next if !f["tuple"]
  next if !f["tuple"][0].is_a? Hash
  next if !f["tuple"][1]["atom"][1]["label"].match(/\/Boundary/)
  table = f["tuple"][0]["atom"][0]["label"].match(/\/(.+)\$/)[1].tableize
  pp table + " <: " + f["label"]
  f["tuple"].each {|t|
    if t.is_a? Hash and t["atom"][1]["label"].match(/\/Boundary/)
      #p "  " + t["atom"][0]["label"].match(/\/(.+)$/)[1] + " -> " + t["atom"][1]["label"].match(/\/(.+)$/)[1] 
      p "  " + t["atom"][0]["label"].match(/\/(.+)$/)[1] + " -> " + boundaries[t["atom"][1]["label"].match(/\/(.+)$/)[1]]
      if boundary_formulas.key?(table)
        boundary_formulas[table].merge!(f["label"] => nil)
      else
        boundary_formulas[table] = Hash.new().merge!(f["label"] => nil)
      end
    end
  }
}; nil

pp boundaries; nil
pp boundary_formulas; nil

int_func = Proc.new {|i|
  #ar = [1, 2, 3, 4, 5, 6, 7, -8, -7, -6, -5, -4, -3, -2, -1, 0].map{|e|e.to_s}
  #ar = [ -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7].map{|e|e.to_s}
  # ar = [-16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].map {|e| e.to_s}
  ar = [-32, -31, -30, -29, -28, -27, -26, -25, -24, -23, -22, -21, -20, -19, -18, -17, -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31].map {|e| e.to_s}
  ar.index(i) + 1
}
=begin
# 具体値の付与定義
# ※加減算しかしていないのであれば、Int値をシフトしても大丈夫。
# とはいえ、加減算している以上、それを何かと較べることで制約づけをしているのだろうから、
# まずは生の値をそのまま見て、制約どおりであるか、あるいは制約定義のほうを間違えていないかチェック。
# それ以外なら、Int値を種として、どう加工しても大丈夫。

=end

c_cities_label = 0
c_merchandises_label = 0
c_shops_label = 0
boundary_formulas =
  {"cities" =>
    {"label" =>
      Proc.new {|i, now|
        c_cities_label += 1
        ["国分寺市", "国立市", "立川市", "府中市", "小平市", "小金井市",
          "東大和市", "松代市"][c_cities_label - 1]
      }},
    "merchandises" =>
      {"label" =>
        Proc.new {|i, now|
          c_merchandises_label += 1
          ["お祝いピンクバラ", "お祝いオレンジバラ", "お誕生日花12月",
            "季節のコーディネート", "和風セット", "お子様セット", "飲食店（夜）開店祝い", "ビジネス開業祝い"][c_merchandises_label - 1]
        }, "price" => Proc.new {|i, now| (i.to_i * 100).abs}},
    "order_details" =>
      {"seq_code" => Proc.new {|i, now| i.to_i + 10},
        "expected_date" => Proc.new {|i, now| now.to_date - 44.days + i.to_i.day},
        #"quantity"=>Proc.new{|i,now| int_func.call(i)}
      },
    "orders" =>
      {"order_code" => Proc.new {|i, now| i.to_i + 100},
        "ordered_at" => Proc.new {|i, now| now.to_date - 44.days + i.to_i.day}},
    "requested_deliveries" =>
      {"order_code" => Proc.new {|i, now| i.to_i + 100},
        #"quantity"=>Proc.new{|i,now| int_func.call(i)}
      },
    "ship_limits" => {
      "expected_date" => Proc.new {|i, now| now.to_date - 44.days + i.to_i.day}},
    "shops" =>
      {"code" => Proc.new {|i, now| i.to_i + 10}, "label" =>
        Proc.new {|i, now|
          c_shops_label += 1
          ["フラワーショップ国立", "花ごよみ国分寺", "立川園芸", "府中生花店", "小金井フラワ−サ−ビス",
            "花のワルツ", "森の小鳥", "高原の小枝", "英国の北欧", "欧米の常識"][c_shops_label - 1]
        },
        #"delivery_limit_per_day"=>
        #  Proc.new{|i,now| int_func.call(i)
        #},
        "mergin" => Proc.new {|i, now| int_func.call(i)}}}

#-------------------------------------------------------------------------------
# Sigのプレースホルダーを用意
sigs = {}
_SigRow = Struct.new(:identifier, :cols)
_SigCol = Struct.new(:name, :val)
hash["alloy"]["instance"]["sig"].each {|s|
  next if %Q(Int seq/Int String this/Univ univ).include?(s["label"]) or
      s["label"].include?("boolean/") or
      s["label"].include?("Boundary")
  next if !s["atom"]
  sigs[s["label"].match(/([^\/]+)$/)[1].tableize] =
      s["atom"].map {|atom|
        label = atom.is_a?(Array) ? atom[1] : atom["label"]
        _SigRow.new(label.match(/([^\/]+)$/)[1].sub(/\$/, "_").tableize.singularize)
      }
}; nil
# pp sigs; nil

# fieldタグを読んではsigsに値として格納していく。
# リレーションは、sigsのキー名を使う。
hash["alloy"]["instance"]["field"].each {|f|
  next if f["label"] == f["label"].tableize
  next if !f["tuple"]
  f["tuple"].each do |t|
    atompair = t.is_a?(Array) ? t[1] : t["atom"]
    rows = sigs[atompair[0]["label"].match(/([^\/]+)$/)[1].split("$")[0].tableize]
    if rows
      key = atompair[0]["label"].match(/([^\/]+)$/)[1].split("$")
      selected_rows = rows.select {|row| row.identifier == key[0].tableize.singularize + "_" + key[1]}
      if selected_rows
        selected_rows.first.cols ||= []
        m = atompair[1]["label"].match(/([^\/]+)$/)
        if m
          if m[1].include?("Boundary")
            # 具体値
            if boundary_formulas[key[0].tableize] and !boundary_formulas[key[0].tableize][f["label"]].blank?
              val = boundary_formulas[key[0].tableize][f["label"]].call(boundaries[m[1]], Time.now)
            else
              val = boundaries[m[1]]
            end
          else
            vals = m[1].split("$")
            if vals.length == 1
              val = m[1]
            else
              val = vals[0].tableize.singularize + "_" + vals[1]
            end
          end
          selected_rows.first.cols.push(_SigCol.new(f["label"], val))
        end
      end
    end
  end
}; nil
pp sigs; nil

sigs.each do |k, v|
  p "==================="
  p k + ".yml"
  p "==================="
  rows = {}
  begin
    v.each {|e|
      h = {};
      h[e.identifier] = {};
      e.cols.each {|s| h[e.identifier][s.name] = s.val};
      #pp h.to_yaml
      rows.merge!(h)
    }
    pp rows
    open("./test/fixtures/order_fullfilled_and_partially/#{k}.yml", "w") do |f|
      YAML.dump(rows, f)
    end
  rescue
  end
end; nil


