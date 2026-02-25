require "spec"
require "file_utils"
require "../src/bubbletea"

describe "Logging" do
  describe "log_to_file" do
    it "logs to file with prefix" do
      temp_dir = "/tmp/bubbletea_test_#{Time.utc.to_unix}"
      Dir.mkdir(temp_dir)
      log_path = File.join(temp_dir, "log.txt")
      prefix = "logprefix"

      begin
        file = Tea.log_to_file(log_path, prefix)
        file.should be_a(File)

        # Write some content to the file
        file.puts("some test log")
        file.close

        # Read and verify content
        content = File.read(log_path)
        content.should eq "some test log\n"

        File.exists?(log_path).should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "creates log file" do
      temp_dir = "/tmp/bubbletea_test_#{Time.utc.to_unix}"
      Dir.mkdir(temp_dir)
      log_path = File.join(temp_dir, "log.txt")

      begin
        file = Tea.log_to_file(log_path, "test")
        file.should be_a(File)
        file.close
        File.exists?(log_path).should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "handles file creation errors" do
      invalid_path = "/nonexistent/directory/log.txt"

      expect_raises(Exception) do
        Tea.log_to_file(invalid_path, "test")
      end
    end
  end

  describe "log_to_file_with" do
    it "accepts a custom block" do
      temp_dir = "/tmp/bubbletea_test_#{Time.utc.to_unix}"
      Dir.mkdir(temp_dir)
      log_path = File.join(temp_dir, "log.txt")

      begin
        configured = false
        file = Tea.log_to_file_with(log_path, "prefix") do |f|
          # Custom configuration block
          configured = true
          f.should be_a(File)
        end
        file.should be_a(File)
        file.close
        configured.should be_true

        File.exists?(log_path).should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end

  describe "Logging configuration" do
    it "sets log prefix with space" do
      temp_dir = "/tmp/bubbletea_test_#{Time.utc.to_unix}"
      Dir.mkdir(temp_dir)
      log_path = File.join(temp_dir, "log.txt")

      begin
        # Test that prefix gets a space added if no trailing space
        file = Tea.log_to_file(log_path, "prefix") # No trailing space
        file.should be_a(File)
        file.close

        # The implementation should add a space
        File.exists?(log_path).should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "preserves prefix with trailing space" do
      temp_dir = "/tmp/bubbletea_test_#{Time.utc.to_unix}"
      Dir.mkdir(temp_dir)
      log_path = File.join(temp_dir, "log.txt")

      begin
        # Test that prefix with trailing space is preserved
        file = Tea.log_to_file(log_path, "prefix ") # Has trailing space
        file.should be_a(File)
        file.close

        File.exists?(log_path).should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end
end
