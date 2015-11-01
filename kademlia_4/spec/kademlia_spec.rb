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

	describe "#==" do
		it "should equal itself" do
			expect(@kc == @kc).to be true
		end
		it "should equal another contact with the same settings" do 
			@kc2 = KademliaContact.new("contact1", "127.0.0.1", "3001")
			expect(@kc == @kc2).to be true
		end
		it "should not be equal to  a contact with different settings." do
			@kc2 = KademliaContact.new("contact1", "127.0.0.1", "3002")
			expect(@kc == @kc2).to be false
		end
	end

	describe "#to_hash and #from_hash" do
		it "self.to_hash.from_hash should equal self" do
			expect(KademliaContact.from_hash(@kc.to_hash) == @kc).to be true
		end
	end
end


describe KademliaBucket do
	before :each do 
		@kb = KademliaBucket.new(100,2**256, {max_bucket_size:2})
		@kc = KademliaContact.new("contact1", "127.0.0.1", "3001")
	end

	describe "#middle_num" do 
		it "should return the middle between start_num and end_num" do
			expect(@kb.middle_num).to eq (@kb.start_num  + (@kb.end_num-@kb.start_num)/2)
		end
	end
	describe "#contains?" do 
		it "should contain a hash that is between start_num and end_num" do
			expect(@kb.contains?("200")).to be true
			expect(@kb.contains?("5FF")).to be true
		end
		it "should not contain numbers outside of its range" do
			expect(@kb.contains?("10")).to be false
			expect(@kb.contains?("30")).to be false
		end
	end
	describe "#size" do 
		it "should be the same as the amount of contacts inside" do 
			expect(@kb.size).to be 0
			@kb << @kc
			expect(@kb.size).to be 1
			expect(@kb.size).to eq @kb.contacts.size
		end
	end
	describe "#<<" do 
		it "should add a new contact" do 
			@kb << @kc
			expect(@kb.contacts).to include(@kc)
		end
		it "should not add a contact more than once" do 
			@kb << @kc
			@kb << @kc
			@kb << @kc
			expect(@kb.size).to be 1
		end
	end
end

describe KademliaBucketList do
	#TODO
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

	# describe "#hash_as_num" do
	# 	it "returns a Numeric" do 
	# 		expect(@kn.hash_as_num("test")).to be_a_kind_of Numeric
	# 	end
	# end

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