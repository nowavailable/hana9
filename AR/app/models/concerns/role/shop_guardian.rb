module Role::ShopGuardian

  def self.extended(shop)
  end

  # 注文明細群のいずれか〜すべてを受けると、
  # 稼働リミットを超えてしまう可能性があるか無いか知りたい。
  def can_recieve_order_safely?(order_details)
    _WorkByDate = Struct.new(:date, :delivery_count)
    work_by_dates = []
    order_details.each do |order_detail|
      count_on_same_date = 0
      # リスト内でこの項目の値はユニ−クに。
      if !work_by_dates.map{|w|w.date}.include?(order_detail.expected_date)
        work_by_dates.push(_WorkByDate.new(order_detail.expected_date))
        count_on_same_date = RequestDelivery.eager_load(:order_detail, :shop).
          where(
            shop_id: self.id,
            order_detail: {expected_date: order_detail.expected_date}
          ).count
      end
      row = work_by_dates.select{|w|w.date = order_detail.expected_date}.first
      row.delivery_count =
        (row.delivery_count or 0) + count_on_same_date + 1
      if row.delivery_count > self.delivery_limit_per_day
        return false
      end
    end
    return true
  end

end