#!/usr/bin/env ruby
require 'redis'

# Connect to Redis
redis = Redis.new

puts "🔍 Analyzing Redis keys..."

# Define patterns for each application
incident_patterns = [
  'stat:*',
  'j|*',
  'retry',
  'processes',
  'queues'
]

banking_patterns = [
  'acc_*',
  /^\d+$/  # numeric keys like "123"
]

# Categorize keys
incident_keys = []
banking_keys = []
unknown_keys = []

redis.keys('*').each do |key|
  if incident_patterns.any? { |pattern| File.fnmatch(pattern, key) }
    incident_keys << key
  elsif banking_patterns.any? { |pattern| pattern.is_a?(Regexp) ? key.match?(pattern) : File.fnmatch(pattern, key) }
    banking_keys << key
  else
    unknown_keys << key
  end
end

puts "\n📊 Found:"
puts "  - Incident Assistant keys: #{incident_keys.count}"
puts "  - Banking application keys: #{banking_keys.count}"
puts "  - Unknown keys: #{unknown_keys.count}"

if banking_keys.any?
  puts "\n🏦 Banking keys found:"
  banking_keys.each { |key| puts "  - #{key}" }
  
  print "\n❓ Do you want to remove banking keys from Redis? (y/n): "
  response = gets.chomp.downcase
  
  if response == 'y'
    banking_keys.each do |key|
      redis.del(key)
      puts "  ✅ Deleted: #{key}"
    end
    puts "\n🧹 Banking keys removed!"
  else
    puts "\n⏭️  Skipping removal."
  end
end

puts "\n💡 Recommendation: Configure your applications to use different Redis databases:"
puts "   - incidentAssistant: redis://localhost:6379/0 (default)"
puts "   - Banking app: redis://localhost:6379/1"
puts "\n   Or use different Redis instances/ports for complete isolation."
