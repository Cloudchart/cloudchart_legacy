class ChangeEmployerFormat < Mongoid::Migration
  def self.up
    Person.ne(work: nil).each do |person|
      person.work.map! do |work|
        if work["employer"].is_a?(Hash)
          work["employer_id"] = work["employer"]["id"]
          work["employer_name"] = work["employer"]["name"]
          work.delete("employer")
        end
        work
      end
      
      if person.changed?
        person.save!
        say "Changed #{person.id}"
      end
    end
  end
end
