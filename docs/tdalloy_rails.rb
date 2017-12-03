# alloy上で仕様記述したそのExamples出力から、テストフィクスチャを生成する。
# rails console 上で実行する。

require 'kconv'
require 'active_support/core_ext/hash/conversions'

xml = open("/home/appuser/Dropbox/0.cnf.xml").read.toutf8
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
  ar = [-16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15].map {|e| e.to_s}
  ar.index(i) + 1
}
=begin
# 具体値の付与定義
# ※加減算しかしていないのであれば、Int値をシフトしても大丈夫。
# とはいえ、加減算している以上、それを何かと較べることで制約づけをしているのだろうから、
# まずは生の値をそのまま見て、制約どおりであるか、あるいは制約定義のほうを間違えていないかチェック。
# それ以外なら、Int値を種として、どう加工しても大丈夫。
boundary_formulas = {"cities"=>{"label"=>
  Proc.new{|i,now|
    val =""
    case i
    when "4"
      val ="国分寺市"
    when "3"
      val ="国立市"
    when "1"
      val ="立川市"
    when "-2"
      val ="府中市"
    end
    }},
 "merchandises"=>{"label"=>
  Proc.new{|i,now|
    val =""
    case i
    when "-2"
      val ="お祝いピンクバラ"
    #when "-7"
    #  val ="お祝いオレンジバラ"
    #when "-2"
    #  val ="お誕生日花12月"
    when "6"
      val ="季節のコーディネート"
    end
  }, "price"=>Proc.new{|i,now| int_func.call(i) * 100}},
 "order_details"=>{"seq_code"=>Proc.new{|i,now| int_func.call(i) + 10},
    "expected_date"=>Proc.new{|i,now| now.to_date - 24.days + int_func.call(i).day},
    "quantity"=>Proc.new{|i,now| int_func.call(i)}},
 "orders"=>{"order_code"=>Proc.new{|i,now| int_func.call(i) + 100},
    "ordered_at"=>Proc.new{|i,now| now.to_date - 24.days + int_func.call(i).day}},
 "requested_deliveries"=>{"order_code"=>Proc.new{|i,now| int_func.call(i) + 100},
   "quantity"=>Proc.new{|i,now| int_func.call(i)}},
 "ship_limits"=>{
    "expected_date"=>Proc.new{|i,now| now.to_date - 24.days + int_func.call(i).day}},
 "shops"=>
  {"code"=>Proc.new{|i,now| int_func.call(i) + 10}, "label"=>
    Proc.new{|i,now|
    val =""
    case i
    when "1"
      val ="フラワーショップ国立"
    when "4"
      val ="花ごよみ国分寺"
    when "-2"
      val ="立川園芸"
    #when "13"
    #  val ="府中生花店"
    #when "-13"
    #  val ="花のワルツ"
    end
  },"delivery_limit_per_day"=>Proc.new{|i,now| int_func.call(i)},
  "mergin"=>Proc.new{|i,now| int_func.call(i) + 1}}}

=end

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
pp sigs; nil

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
  v.each {|e|
    h = {};
    h[e.identifier] = {};
    e.cols.each {|s| h[e.identifier][s.name] = s.val};
    #pp h.to_yaml
    rows.merge!(h)
  }
  pp rows
  open("./#{k}.yml", "w") do |f|
    YAML.dump(rows, f)
  end
end; nil

