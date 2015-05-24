#CRYPTO
def encrypt_file(in_file, out_file, password)
	openssl_command = "openssl aes-256-cbc -salt -in \"#{in_file}\" -out \"#{out_file}\" -pass pass:#{password}"
	if !system(openssl_command) then
		puts "FATAL: Error while encrypting file"
		exit
	end
end

def decrypt_file(in_file, out_file, password)
	openssl_command = "openssl aes-256-cbc -d -in \"#{in_file}\" -out \"#{out_file}\" -pass pass:#{password}"
	system(openssl_command)
	if !system(openssl_command) then
		puts "FATAL: Error while decrypting file"
		exit
	end
end
