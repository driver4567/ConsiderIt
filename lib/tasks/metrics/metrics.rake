require 'uri'

namespace :metrics do
  desc "Create metrics output"

  task :deeper => :environment do
    puts "Number\tName\tpositions\tpoints\tinclusions\tInclusions per point\tInclusions per position"
    Proposal.where(:domain_short => 'WA State').each do |p|
      printf("%i\t%s\t%i\t%i\t%i\t%.2f\t%.2f\n",
        p.designator,p.short_name,p.positions.published.count,p.points.published.count,p.inclusions.count,
        p.inclusions.count.to_f / p.points.published.count,
        p.inclusions.count.to_f / p.positions.published.count)
    end
  end

  task :basic => :environment do

    years = [2010,2011,2012]
    puts "Overall activities"
    puts "Year\tusers\tpositions\tinclusions\tpoints\tcomments"
    years.each do |year|
      positions = Position.published.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')
      users = User.where(:account_id => 1).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')
      points = Point.published.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')      
      inclusions = Inclusion.where(:account_id => 1).where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins(:position).where('positions.published = 1')
      comments = Commentable::Comment.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')

      printf("%i\t%s\t%i\t%i\t%i\t%i\n",
          year, users.count, positions.count, inclusions.count, points.count, comments.count)

    end

    years = [2010,2011,2012]
    puts "Distinct users engaging in each activity"
    puts "Year\tusers\tpositions\tinclusions\tpoints\tcomments"
    years.each do |year|
      positions = Position.published.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').group(:user_id)
      users = User.where(:account_id => 1).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')
      points = Point.published.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').group(:user_id)
      inclusions = Inclusion.where(:account_id => 1).where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins(:position).where('positions.published = 1').group("inclusions.user_id")
      comments = Commentable::Comment.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').group(:user_id)

      printf("%i\t%s\t%i\t%i\t%i\t%i\n",
          year, 
          users.count, 
          positions.count.keys.length, 
          inclusions.count.keys.length, 
          points.count.keys.length, 
          comments.count.keys.length)

    end

    years = [2010,2011,2012]
    puts "Advanced metrics"
    puts "Year\tInclusions per point\tinclusions per position\tcomments per point\tpositions per user"
    years.each do |year|
      positions = Position.published.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')
      users = User.where(:account_id => 1).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')
      points = Point.published.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')      
      inclusions = Inclusion.where(:account_id => 1).where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins(:position).where('positions.published = 1')
      comments = Commentable::Comment.where(:account_id => 1).where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8')

      printf("%i\t%.2f\t%.2f\t%.2f\t%.2f\n",
          year, 
          inclusions.count.to_f / points.count, #inclusions per point
          inclusions.count.to_f / positions.count, #inclusions per position
          comments.count.to_f / points.count, #comments per point
          positions.count.to_f / users.count #positions per user
      )
    end

  end

  task :referer => :environment do 
    puts "User referals"
    year = 2012
    users = User.where(:account_id => 1).where("YEAR(created_at)=#{year} OR YEAR(last_sign_in_at)=#{year}").where('MONTH(created_at)>8')

    domains = {}

    users.each do |user|
      begin
        domain = URI.parse(user.referer).host
        if user.referer.index('aclk')
          domain = 'google.ads.com'
        end
      rescue
        domain = nil
      end


      if !domains.has_key?(domain)
        domains[domain] = {:users => 0, :positions => 0, :points => 0, :inclusions => 0}
      end
      domains[domain][:users] += 1 
      domains[domain][:positions] += user.positions.published.where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').count
      domains[domain][:points] += user.points.published.where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').count      
      domains[domain][:inclusions] += user.inclusions.where("YEAR(inclusions.created_at)=#{year}").where('MONTH(inclusions.created_at)>8').joins(:position).where('positions.published = 1').count
      #domains[domain][:comments] += user.comments.where("YEAR(created_at)=#{year}").where('MONTH(created_at)>8').count      
    end

    as_array = []; domains.each {|k,vs| as_array.push([k,vs]) }  

    puts( "Domain\tusers\tpositions\tinclusions\tpoints")
    as_array.sort{|x,y| x[1][:users]<=>y[1][:users]}.each do |domain|
        printf("%s\t%i\t%i\t%i\t%i\n",

        domain[0], 
        domain[1][:users],
        domain[1][:positions],
        domain[1][:inclusions],
        domain[1][:points]
        #domain[:comments]
      )
    end
  end




end