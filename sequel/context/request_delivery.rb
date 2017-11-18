class RequestDelivery
  #
  # "管理者が、注文を配送指示したい。"
  #
  attr_accessor :fullfilled_shops_profitable , :fullfilled_shops_leveled,
    :partial_shops_profitable, :partial_shops_leveled

  # ある注文に対して、それを配送できる加盟店の候補をリストを提示する。
  def propose

  end
end