class Date
  class << self
    def from_params(params, name)
      return nil unless params.is_a?(Hash)
      y, m, d = params.values_at("#{ name }(1i)", "#{ name }(2i)", "#{ name }(3i)").map { |v| v.to_i unless v.blank? }
      if y and m and d
        Date.new(y, m, d)
      else
        nil
      end
    end
  end
end
