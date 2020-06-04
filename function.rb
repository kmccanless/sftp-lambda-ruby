require 'json'
require 'aws-sdk-ssm'
require 'aws-sdk-s3'
require 'net/sftp'

def handler(*)
  host = ''
  user = ''
  password = ''
  bucket = ''
  key = ''

  puts 'Starting function'

  ssm_client = Aws::SSM::Client.new(region: 'us-east-2')
  resp = ssm_client.get_parameters(
      names: %w[secret user host bucket key], # required
      with_decryption: true
  )

  puts 'Looping thru parameters'

  resp.parameters.each do |param|
    if param.name == 'secret'
      password = param.value
      puts 'password retrieved'
    elsif param.name == 'host'
      host = param.value
      puts "host is #{host}"
    elsif param.name == 'user'
      user = param.value
      puts "user is #{user}"
    elsif param.name == 'bucket'
      bucket = param.value
      puts "bucket is #{bucket}"
    elsif param.name == 'sftp-key'
      key = param.value
      puts "key is #{key}"
    end
  end

  puts 'Calling SFTP server'

  Net::SFTP.start(host, user, password: password) do |sftp|
    # grab data off the remote host directly to a buffer
    data = sftp.download!('/pub/example/readme.txt')
    puts data

    s3_client = Aws::S3::Client.new(region: 'us-east-2')
    resp = s3_client.put_object(
        body: data,
        bucket: bucket,
        key: key
    )
  end
end