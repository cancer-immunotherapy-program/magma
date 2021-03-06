module Labors
  class Victim < Magma::Model
    parent :monster

    restricted

    identifier :name, type: String
    attribute :country, type: String, restricted: true
  end
end
