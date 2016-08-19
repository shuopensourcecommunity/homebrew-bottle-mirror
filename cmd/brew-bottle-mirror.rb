require "formula"

Formula.core_files.each do |fi|
    begin
      f = Formula[fi]
    rescue Exception => e
      opoo "#{fi}: something goes wrong."
      puts e.message
      puts e.backtrace.inspect
      next
    end
      
    next unless f.bottle_defined?

    bottle_spec = f.stable.bottle_specification
    bottle_spec.collector.keys.each do |os|
      next if os == :x86_64_linux
      checksum = bottle_spec.collector[os]
      next unless checksum.hash_type == :sha256
      filename = Bottle::Filename.create(f, os, bottle_spec.rebuild)
      if ENV['HOMEBREW_TAP'].nil?
          root_url = bottle_spec.root_url
      else
          if ENV['HOMEBREW_BOTTLE_DOMAIN'].nil?
              root_url = "http://homebrew.bintray.com/bottles-#{ENV['HOMEBREW_TAP']}"
          else
              root_url = "#{ENV['HOMEBREW_BOTTLE_DOMAIN']}/bottles-#{ENV['HOMEBREW_TAP']}"
          end
      end
      url = "#{root_url}/#{filename}"

      file = HOMEBREW_CACHE/filename
      tmpfile = HOMEBREW_CACHE/"#{filename}.tmp"
      next if File.exist?(file)

      begin
        curl "-sSL", "-m", "600", url, "-o", tmpfile
        tmpfile.verify_checksum(checksum)
      rescue ErrorDuringExecution
        FileUtils.rm_f tmpfile
        opoo "Failed to download #{url}"
        next
      rescue ChecksumMismatchError => e
        FileUtils.rm_f tmpfile
        opoo "Checksum mismatch #{url}"
        next
      end
      FileUtils.mv(tmpfile, file)
      ohai  "#{filename} downloaded"

    end
end
