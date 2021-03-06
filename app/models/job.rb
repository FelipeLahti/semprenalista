class Job
  
  def run email=nil    
    parties = Party.all
    clubber = find email, parties
    return log('Everybody is already subscribed \o/') unless clubber
    
    clubber.remove_expired_subscriptions parties
    subscribe clubber, parties
  end
  
  private
  
  def find email, parties
    email ? Nightclubber.where(:email => email).first : Nightclubber.next_to_subscribe(parties)
  end
  
  def subscribe clubber, parties
    clubber.find_missing_from(parties).each do |party|
      begin
        log "Subscribing #{clubber.email} to #{party.name}..."
        response = party.add_to_list clubber
        clubber.add Subscription.new(party, response)
        clubber.save
        log 'OK.'
      
      rescue => e  
        log "Unable to add #{clubber.email} to #{party.name}."
        log "Reason: #{e}"
      end
    end
    log 'Done.' 
  end
  
  def log message
    puts "[JOB] #{message}"
  end

end

