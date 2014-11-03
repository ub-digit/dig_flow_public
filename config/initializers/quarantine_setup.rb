class Quarantine
  def self.find_by_id(*args)
    self.new
  end

  def id
    0
  end

  def name
    # Quarantine => quarantined
    # Unquarantine => unquarantined
    self.class.to_s.downcase+"d"
  end
end

class Unquarantine < Quarantine; end
