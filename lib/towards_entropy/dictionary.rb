module TowardsEntropy
  class Dictionary
    attr_accessor :id, :bytes

    def initialize(id, bytes)
      @id = id
      @bytes = bytes
    end
  end
end