module ALD
  class InvalidPackageError < StandardError
  end

  class NoDefinitionError < InvalidPackageError
  end

  class InvalidDefinitionError < StandardError
  end
end