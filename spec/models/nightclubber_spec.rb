describe Nightclubber do
  
  context 'when creating a new instance' do
    before :each do
      @sabella = Nightclubber.new 'Filipe Sabella', 'lipe@gmail.com', ['Marano', 'Pedro']
    end

    it 'should have a name' do
      @sabella.name.should be == 'Filipe Sabella'
    end

    it 'should have an email' do
      @sabella.email.should be == 'lipe@gmail.com'
    end

    it 'should tell me who are his friends' do
      @sabella.friends.should =~ ['Marano', 'Pedro']
    end
    
    it 'should use his email as identity' do
      same = mock
      same.stub(:email).and_return 'lipe@gmail.com'
      @sabella.should be == same
    end
    
    it 'should not have any subscriptions by default' do
      @sabella.subscriptions.should be_empty
    end
    
    context 'with subscriptions' do

      before :each do
        @amnesia = fake_party 'http://www.cabaretpoa.com.br/amnesia.htm'
        @rocket = fake_party 'http://www.cabaretpoa.com.br/rocket.htm'
        @sabella.add Subscription.new(@rocket, fake_response)
        
        @ygor = Nightclubber.new 'Ygor Bruxel', 'ygor@gmail.com', []
        @ygor.add Subscription.new(@rocket, fake_response)
        @ygor.stub!(:updated_at).and_return Time.now
        
        Nightclubber.stub!(:all).and_return [@ygor, @sabella]
      end

      it 'should be able to identify when he was subscribed to a party' do
        @sabella.should be_subscribed_to @rocket
      end  

      it 'should be able to identify the parties he wasnt subscribed yet' do
        @sabella.find_missing_from([@amnesia, @rocket]).should be == [@amnesia]
      end

      it 'should remove the expired ones' do
        @sabella.remove_expired_subscriptions [@amnesia]
        @sabella.should_not be_subscribed_to @rocket
      end
      
      it 'should need new subscriptions for the missing parties' do
        Nightclubber.need_subscription([@amnesia, @rocket]).should include @sabella
      end
      
      it 'should not need more subscriptions when subscribed to all parties' do
        @sabella.add Subscription.new(@amnesia, fake_response)
        Nightclubber.need_subscription([@amnesia, @rocket]).should_not include @sabella
      end
        
      it 'should be the next one to be subscribed when he wasnt updated yet' do
        @sabella.stub!(:updated_at).and_return nil
        Nightclubber.next_to_subscribe([@amnesia, @rocket]).should be == @sabella
      end
      
      it 'should be the next one to be subscribed when he has the oldest update' do
        @sabella.stub!(:updated_at).and_return @ygor.updated_at - 1
        Nightclubber.next_to_subscribe([@amnesia, @rocket]).should be == @sabella
      end
      
      it 'should be included in all subscriptions' do
        Nightclubber.all_subscriptions.should =~ (@sabella.subscriptions + @ygor.subscriptions)
      end
      
      it 'should be included in the missing reports' do
        missing = Nightclubber.missing_emails_with_party_urls [@amnesia, @rocket]
        missing.should =~ [{
          :email => 'lipe@gmail.com', 
          :party_url => 'http://www.cabaretpoa.com.br/amnesia.htm'
        }, {
          :email => 'ygor@gmail.com', 
          :party_url => 'http://www.cabaretpoa.com.br/amnesia.htm'
        }]
      end

    end
    
  end

  context 'when parsing request parameters' do
    
    context 'for a new instance' do
      before :each do
        @sabella = Nightclubber.parse params
      end

      it 'should be able to extract the name' do
        @sabella.name.should be == 'Jose Bartiella'
      end

      it 'should be able to extract the email' do
        @sabella.email.should be == 'lipe@tw.com'
      end

      it 'should be able to extract the friends' do
        @sabella.friends.should =~ ['Thiago']
      end
    end
    
    context 'for an existing instance' do
      it 'should be able to change the name and friends' do
        @sabella = Nightclubber.empty
        
        @sabella.should_receive(:update_attributes).with(
          :name => 'Jose Bartiella', 
          :friends => ['Thiago'])
        
        @sabella.parse params
      end
    end  
    
  end
  
  it 'should not be valid without name' do
    unamed = Nightclubber.new '', 'lipe@gmail.com', ['Marano']
    unamed.should_not be_valid
  end
  
  it 'should be fine without friends' do
    lonely = Nightclubber.new 'Filipe Sabella', 'lipe@gmail.com', []
    lonely.should be_valid
  end
  
  context 'when validating names' do
    
    before do
      @illegal = ['.', '"', '\'', '\\', '/', '<', '>', '&', '%']
    end
    
    it 'should not accept illegal characters in his name' do
      @illegal.each do |name|
        troll = Nightclubber.new name, 'lipe@gmail.com', ['Marano']
        troll.should_not be_valid 
      end
    end
    
    it 'should not accept illegal characters in his friends names' do
      @illegal.each do |name|
        troll = Nightclubber.new 'Filipe Sabella', 'lipe@gmail.com', [name]
        troll.should_not be_valid 
      end
    end
    
  end
  
  it 'should not be valid without email' do
    emailess = Nightclubber.new 'Filipe Sabella', '', ['Marano']
    emailess.should_not be_valid
  end
  
  context 'when validating email' do
    
    before do
      @illegal = ['"', '\'', '\\', '/', '<', '>', '&', '%']
    end
    
    it 'should not accept illegal characters in his email' do
      @illegal.each do |email|
        troll = Nightclubber.new 'Filipe Sabella', email, ['Marano']
        troll.should_not be_valid 
      end
    end
    
  end
  
  it 'should create an empty new instance' do
    empty = Nightclubber.empty
    empty.name.should be == ''
    empty.email.should be == ''
    empty.friends.each{|f| f.should be == ''}
  end
  
  it 'should not find the next one to subscribe when everybody is in all list' do
    Nightclubber.stub!(:need_subscription).and_return []
    Nightclubber.next_to_subscribe([mock]).should be_nil
  end
  
  def fake_party url
    party = mock
    party.stub!(:url).and_return url
    party
  end
  
  def fake_response
    response = mock
    response.stub!(:code).and_return 200
    response.stub!(:message).and_return 'ok'
    response
  end
  
  def params
    {
      :name => 'Jose Bartiella',
      :email => 'lipe@tw.com',
      :friends => {
        :f0 => 'Thiago',
        :f1 => '',
        :f2 => '',
        :f3 => ''
      }
    }
  end

end
