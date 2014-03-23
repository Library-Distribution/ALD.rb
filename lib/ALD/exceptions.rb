module ALD
  class InvalidPackageError < StandardError
  end

  class NoDefinitionError < InvalidPackageError
  end

  class InvalidDefinitionError < StandardError
  end

  class AuthenticationError < StandardError
  end

  class UnsupportedAuthMethodError < AuthenticationError
  end

  class NoAuthError < AuthenticationError
  end

  class InvalidAuthError < AuthenticationError
  end
end