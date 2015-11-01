require 'spec_helper'
require 'kademlia'



describe KademliaContact do 

	before :each do 
		@kc = KademliaContact.new("contact1", "127.0.0.1", "3001")
	end	

	describe "@node_id" do 
		it "should hash the passed identifier and keep it as node_id" do 
			expect(@kc.node_id).to eq ($digest_class.digest "contact1")
		end
	end
	describe "@custom_time" do
		it "should keep track of the last contact_time if created with a different time" do 
			custom_time = Time.now() - 3600
			@kc2 = KademliaContact.new("contact2", "127.0.0.1", "3002", contact_time: custom_time)
			expect(@kc2.last_contact_time).to eq custom_time
		end
	end
end

describe KademliaNode do
	before :each do 
		@kn = KademliaNode.new("test_identifier", [
			KademliaContact.new("contact1", "127.0.0.1", "3001"),
			KademliaContact.new("contact2", "127.0.0.1", "3002")
			])
	end

	describe "#new" do 
		it "takes at least one parameter and returns a KademliaNode" do 
			expect(@kn).to be_an_instance_of KademliaNode
		end
	end

	describe "#hash_as_num" do
		it "returns a Numeric" do 
			expect(@kn.hash_as_num("test")).to be_a_kind_of Numeric
		end
	end

	describe "#calc_distance" do
		it "takes two hashes as parameters and returns a Numeric object" do 
			expect(@kn.calc_distance('100', '100')).to be_a_kind_of Numeric
		end

		it "has distance 0 when hashes are the same" do 
			expect(@kn.calc_distance('100', '100')).to eq 0
		end

		it "has distance > 0 when hashes are not the same." do 
			expect(@kn.calc_distance('100', '101')).to_not eq 0
		end
		it "does not mind the order of the hashes" do 
			expect(@kn.calc_distance('100', '101')).to eq @kn.calc_distance('101', '100')
		end
	end


	describe "#bucket_for_hash" do 
		it "takes a hash and returns hash index" do
			result = @kn.bucket_for_hash('contact1')
			expect(result).to be_a_kind_of Numeric
			expect(result).to be < @kn.contact_buckets.length
		end
	end

	describe "#add_contact_to_buckets" do 
		it "adds a contact to the correct bucket" do
			contact = KademliaContact.new("contact3", "127.0.0.1", "3003")
			@kn.add_contact_to_buckets(contact)
			expect(@kn.bucket_for_hash("contact3")).to include(contact)
		end
	end

	describe "#sort_bucket_contracts" do 
		it "sorts all buckets, prefering ones wight older `last_contact_time`" do 
			sorted_bucket = @kn.sort_bucket_contacts(0)
			bucket_times = sorted_bucket.map {|e| e.last_contact_time}
			is_sorted = bucket_times.each_cons(2).all? { |a, b| (a <=> b) <= 0 }
			expect(is_sorted).to be true
		end
	end

	describe "#save_closest_contact" do 
		it "should return an empty array when passed an empty array" do 
			expect(@kn.save_closest_contact([], $digest_class.digest("100")).empty?).to be true
		end
		it "should return an array [closest contact, distance to this contact], when being passed multiple" do 
			closest_contact = KademliaContact.new("102", "127.0.0.1", "3004")
			close_contacts = [
					closest_contact,
					KademliaContact.new("101", "127.0.0.1", "3005"),
					KademliaContact.new("103", "127.0.0.1", "3006")
				]
			result = @kn.save_closest_contact(close_contacts, $digest_class.digest("100"))
			expect(result.length).to eq 2
			expect(result.first).to eq closest_contact
			expect(result.last).to eq @kn.calc_distance($digest_class.digest("100"),$digest_class.digest("102"))
		end
	end
end