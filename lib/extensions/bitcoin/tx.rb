module Bitcoin
  class Tx
    def colored?
      open_assets?
    end

    def open_assets?
      !outputs.find(&:open_assets_marker?).nil?
    end
  end
end