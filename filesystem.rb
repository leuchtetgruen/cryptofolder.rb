require 'tempfile'
require 'json'
require 'digest/sha2'

#INDEX-HANDLING
def temp_index
	Tempfile.new('index')
end

def write_index(index_file, h_index, password)
	tmp_idx = temp_index
	tmp_idx.write(h_index.to_json)
	tmp_idx.close

	encrypt_file(tmp_idx.path, index_file, password)
	#tmp_idx.unlink
end

def build_encrypted_filename(orig_filename)
	s_random1 = (0...16).map { (65 + rand(26)).chr }.join
	s_random2 = (0...16).map { (65 + rand(26)).chr }.join
	full_str = "#{s_random1}#{orig_filename}#{s_random2}"
	Digest::SHA2.hexdigest(full_str)
end

def add_to_index(index_file, orig_filename, password)
	h = read_index_hash(index_file, password)
	encrypted_fn = build_encrypted_filename(orig_filename)
	h[encrypted_fn] = orig_filename

	write_index(index_file, h, password)
end

def remove_from_index(index_file, orig_filename, password)
	h = read_index_hash(index_file, password)
	enc_fn = h.invert[orig_filename]
	h.delete(enc_fn)

	write_index(index_file, h, password)
end

def read_index_hash(index_file, password)
	return {} if !File.exist?(index_file)


	tmp_idx = temp_index
	decrypt_file(index_file, tmp_idx.path, password)

	s_content = File.read(tmp_idx.path)
	h_content = JSON.parse(s_content)
	
	tmp_idx.unlink

	h_content
end

def encrypted_file_list(index_file, password)
	h = read_index_hash(index_file, password)
	h.keys
end

def decrypted_file_list(index_file, password)
	h = read_index_hash(index_file, password)
	h.invert.keys
end

# FILENAME BUILDING
def get_encrypted_filename(index_file, folder_enc, dec_filename, password)
	h = read_index_hash(index_file, password).invert
	"#{folder_enc}/#{h[dec_filename]}"
end

def get_decrypted_filename(index_file, folder_dec, enc_filename, password)
	h = read_index_hash(index_file, password)
	"#{folder_dec}/#{h[enc_filename]}"
end

def clean_filename(filename, orig_path)
	#TODO use proper means
	filename.gsub(orig_path, "")
end
