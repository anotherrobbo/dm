require 'zip'

class ManifestJob < ApplicationController
    include SuckerPunch::Job
    workers 1
    
    Zip.on_exists_proc = true
    ManifestJob.perform_in(1)
    
    def perform()
        @@log.info("Checking last manifest updated...")
        lastUpdate = Rails.cache.read("MANIFEST_UPDATE_DATE")
        
        if lastUpdate != nil && lastUpdate > 1.second.ago
            @@log.info("Last updated less than 1 day ago so skipping load - #{lastUpdate}")
            secs = (lastUpdate + (24 * 60 * 60)) - Time.now
            @@log.info("Scheduling next refresh for #{secs} seconds from now")
            ManifestJob.perform_in(secs)
        else
            @@log.info("Reloading manifest data")
            data = jsonCall(@@bungieURL + "/Platform/Destiny/Manifest/")
            dbPath = data["Response"]["mobileWorldContentPaths"]["en"]
            @@log.info("downloading data: #{dbPath}")
            open("tmp/manifest.zip", "wb") do |file|
                file << open(@@bungieURL + dbPath).read
            end
            @@log.info("Download complete, unzipping data")
            
            Zip::File.open("tmp/manifest.zip") do |zipfile|
                zipfile.each do |zipped|
                    zipfile.extract(zipped, "tmp/manifest.sqlite")
                end
            end
            @@log.info("Unzipping complete, processing data")

            db = SQLite3::Database.new "tmp/manifest.sqlite"
            loadFromTable(db, "DestinyClassDefinition", "class")
            loadFromTable(db, "DestinyRaceDefinition", "race")
            loadFromTable(db, "DestinyGenderDefinition", "gender")
            loadFromTable(db, "DestinyActivityDefinition", "activity")
            loadFromTable(db, "DestinyActivityTypeDefinition", "activityType")
            @@log.info("Manifest data updated, scheduling next refresh for 1 day from now")

            Rails.cache.write("MANIFEST_UPDATE_DATE", Time.now)
            ManifestJob.perform_in(24 * 60 * 60)
        end
    end
    
    protected def loadFromTable(db, tableName, type)
        db.execute( "select json from #{tableName}" ) do |row|
            jsonRow = JSON.parse(row[0])
            hash = jsonRow["hash"]
            @@log.debug("Caching #{type}/#{hash}")
            Rails.cache.write("#{type}-#{hash}", jsonRow)
        end
    end

end