require File.expand_path(File.dirname(__FILE__) + '/agent')

module Beco
  extend Agent
  
  def self.home 
    'http://www.beco203.com.br'
  end
  
  class Navigator
    def initialize
      @page = Beco.get 'capa-beco.php'
    end

    def name
      'Beco'
    end

    def navigate_to_parties
      links = @page.links_with(:href => /agenda-beco.php\?c=/i)
      links = links.inject({}){ |h, l| h[l.href] = l; h}.values
      links.map{ |l| PartyNavigator.new(l.click) }
    end
  end

  class PartyNavigator
    def initialize page
      @page = page
    end

    def find_name
      @page.search('div.conteudo-interna h1 strong').first.text.strip
    end

    def url
      @page.uri.to_s
    end

    def navigate_to_list
      code = url.match(/.*=(.+)\z/i).captures[0]
      regex = eval("/agenda_nomenalista.php\\?c=#{code}/i")
      link = @page.link_with(:href => regex)
      link ? DiscountListNavigator.new(link.click) : nil
    end
  end

  class DiscountListNavigator
    def initialize page
      @form = page.form_with(:action => 'agenda_nomenalista.php')
    end

    def fill_name name
      @form['nome'] = name
    end

    def fill_email email
      @form['email'] = email
    end

    def fill_friends friends
      fields = @form.fields_with(:name => /nome_amigo/i)
      friends.each_with_index do |friend, i|
        fields[i].value = friend
      end
    end

    def submit
      response_page = Beco.submit @form
      ResponseNavigator.new(response_page)
    end
  end

  class ResponseNavigator
    def initialize page
      @page = page
    end

    def code
      @page.code
    end

    def find_message
      @page.search('body').first.text.strip
    end
  end
end

