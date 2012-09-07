#!/usr/bin/env ruby

require 'digest/sha1'

raise "define source & dest" if ARGV.size != 2

def hashsum(file)
  hasher = Digest::SHA1.new
  File.open(file, "r") do |io|
    while (!io.eof)
      hasher.update(io.readpartial(10240))
    end
  end
  hasher.hexdigest
end

def scan_dir(source, &block)
  source = source[0..-2] if source.end_with?("/")
  Dir.glob(File.join(source, "**/*")).each do |full_path|
    block.call(full_path[source.size+1..-1])
  end
end

source, dest = ARGV
missing_paths = []
changed_paths = []
changed_size = []
changed_checksum = []
source_files = {}
changed_mtime = []
scan_dir(source) do |short_path|
  source_files[short_path]=nil
  source_path = File.join(source, short_path)
  dest_path = File.join(dest, short_path)
  if File.exists?(dest_path)
    if File.directory?(source_path) && File.directory?(dest_path)
    elsif File.file?(source_path) && File.file?(dest_path)
	  if File.size(source_path) != File.size(dest_path)
	    changed_size << short_path
	  else
	   if File.mtime(source_path) != File.mtime(dest_path)
	     changed_mtime << short_path
	   end
#	  elsif hashsum(source_path) != hashsum(dest_path)
#        changed_checksum << short_path
      end
    else
      changed_paths << short_path
    end
  else
    missing_paths << short_path
  end
end

new_paths = []

scan_dir(dest) do |short_path|
  if !source_files.include?(short_path)
    new_paths << short_path
  end
end

output_line = false
puts "Contents of '#{dest}' vs '#{source}'"
[
    ["Missing files", "-", missing_paths],
    ["New files", "+", new_paths],
    ["Changed file size", "!-size:", changed_size],
    ["Changed file checksum", "!-checksum:", changed_checksum],
    ["Changed file modification time", "!-mtime:", changed_mtime],
    ["Changed type", "!-type:", changed_paths]
].each do |str, type, list|
  if list.size > 0
    if output_line
      puts "-------------------------------------------------------------------------------------"
    end
    puts "#{str} (#{list.size}):"
    puts list.map { |s| "#{type} #{s}" }.join("\n")
    output_line = true
  end
end
if !output_line
  puts "No changes"
end
