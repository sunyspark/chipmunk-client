require "fileutils"

# We wrap the filesystem for easy mocking,
# and to be clear about which methods we need.
class Filesystem
  # Create a directory and all intermediate
  # directories. Idempotent.
  def mkdir_p(path)
    FileUtils.mkpath path
  end
end
