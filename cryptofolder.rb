require 'rubygems'
require 'listen'
require 'fileutils'
require 'mkmf'
require 'io/console'

$: << "."
require 'crypto'
require 'filesystem'

# CHECK PREREQUISITES
if !find_executable("openssl") then
	puts "Cannot find OpenSSL binary. Please install it and put it into your PATH before using this program"
	exit
end

if ARGV.size != 2 then
	puts "You need to provide an existing input folder (for encrypted files) and an output folder (for decrypted files)"
	puts "Use it like this: #{$PROGRAM_NAME} IN_FOLDER OUT_FOLDER"
	exit
end

@folder_enc = ARGV[0]
@folder_dec = ARGV[1]


# MAIN PROGRAM


#TODO use proper path building
@index_file = "#{@folder_enc}/index" 

print "Password:"
@password = STDIN.noecho(&:gets).chomp

# STEP 1 - CREATE DIRECTORIES IF NECESSARY
if !Dir.exist?(@folder_enc) then
	Dir.mkdir(@folder_enc)
end
if !File.exist?("#{@folder_enc}/INSTRUCTIONS.txt") then
	FileUtils.copy("INSTRUCTIONS.txt", "#{@folder_enc}/INSTRUCTIONS.txt")
end
if !Dir.exist?(@folder_dec) then
	Dir.mkdir(@folder_dec)
end

# STEP 2 - DECRYPT FILES
puts "Decrypting files..."
@pre_existing_files = Dir.glob("#{@folder_dec}/**/*").to_a
encrypted_file_list(@index_file, @password).each do |enc_file|
	full_enc_file = "#{@folder_enc}/#{enc_file}"
	dec_file = get_decrypted_filename(@index_file, @folder_dec, clean_filename(enc_file, @folder_enc), @password)

	# Create folders if necessary
	basefolder = File.dirname(dec_file)
	if (!File.exist?(basefolder)) then
		Dir.mkdir(basefolder)
	end

	decrypt_file(full_enc_file, dec_file, @password)
end
puts "Done."

# STEP 3 - LISTEN
listener = Listen.to(@folder_dec) do |modified, added, removed|
	removed.each do |f_removed|
		# remove encrypted file as well and remove from index
		puts "Removing #{f_removed}"
		clean_fn = clean_filename(f_removed, @folder_dec)
		enc_filename = get_encrypted_filename(@index_file, @folder_enc, clean_fn, @password) 
		File.unlink(enc_filename)
		remove_from_index(@index_file, clean_fn, @password)
	end

	modified.each do |f_modified|
		# re-encrypt file
		puts "Re-encrypting #{f_modified}"
		enc_filename = get_encrypted_filename(@index_file, @folder_enc, clean_filename(f_modified, @folder_dec), @password) 
		encrypt_file(f_modified, enc_filename, @password)
	end

	added.each do |f_added|
		# add to index and encrypt
		puts "Adding file #{f_added}"
		clean_fn = clean_filename(f_added, @folder_dec)
		add_to_index(@index_file, clean_fn, @password)
		enc_filename = get_encrypted_filename(@index_file, @folder_enc, clean_fn, @password) 
		
		basefolder = File.dirname(enc_filename)
		if (!File.exist?(basefolder)) then
			Dir.mkdir(basefolder)
		end

		encrypt_file(f_added, enc_filename, @password)
	end
end
listener.start

trap "SIGINT" do
	#REMOVE DECRYPTED FILES

	Dir.glob("#{@folder_dec}/**/*").each do |fn|
		if !@pre_existing_files.include?(fn) then
			if File.directory?(fn) then
				FileUtils.rm_r(fn) 
			else
				# could have been deleted previously
				File.delete(fn) if File.exist?(fn)
			end
		end
	end
	exit 130
end

sleep

