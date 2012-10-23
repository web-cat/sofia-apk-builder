#
# Sofia APK Builder
#
# Authors: Ellen Boyd, Tony Allevato
#

$: << File.dirname(__FILE__) + "/lib" # add lib folder to require path
require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra'
require 'ed_auth.rb'
require 'sinatra/flash'
require 'sinatra/config_file'
require 'zip/zip'
require 'open3'
require 'find'

class SofiaAPKBuilder < Sinatra::Base

  #~ Configuration ............................................................

  set :haml, { :format => :html5 }

  enable :sessions

  # Register extensions.
  register Sinatra::Flash
  register Sinatra::ConfigFile

  config_file 'appconfig.yml'


  #~ Routes ...................................................................

  # -------------------------------------------------------------
  # GET /
  # The main index URL.
  get '/' do
    haml :index
  end


  # -------------------------------------------------------------
  # POST /build
  # Called when the main index form is submitted.
  post '/build' do
    @pid = params['pid']
    password = params['password']

    if Sinatra::Base.development?
      authed = true
    else
      ed_auth = EdAuth.new(@pid, password)
      authed = ed_auth.authenticate
    end

    if !authed
      flash[:error] = 'Your PID or password was incorrect.'
      redirect to('/')
    elsif !params['file']
      flash[:error] = 'You must provide a ZIP file containing your project source code.'
      redirect to('/')
    else
      process_submission @pid
      haml :build
    end
  end


  # -------------------------------------------------------------
  # GET /download/:pid
  # Called when the user clicks the download link to retrieve his or her
  # built APK file.
  get '/download/:pid' do
    pid = params[:pid]
    send_file File.join("storage", "#{pid}", "build", "bin",
      "sofia.micro.wombats-debug.apk"),
      :filename => "sofia.micro.wombats-#{pid}.apk"
  end


  private

  #~ Helper methods ...........................................................

  # ---------------------------------------------------------------
  # Process a student's successful permission: unzip it, merge it with a
  # master project, then run Ant to build it.
  def process_submission(pid)
    student_dir = "storage/#{pid}"
    build_dir = "#{student_dir}/build"
    # Prepare the build area.
    FileUtils.rm_rf build_dir
    FileUtils.mkdir_p build_dir

    # Unzip the student's submitted files.
    
  	unzip_file params['file'][:tempfile].path, build_dir
  	find_src_files build_dir, pid

      # Merge in the master project.
  	find_src_files build_dir, pid
  	
  	merge_src_files build_dir, pid
  	merge_master_project build_dir
      # Run Ant.
      Dir.chdir build_dir do
        stdin, stdout, stderr = Open3.popen3('ant debug')
        @build_output = stdout.readlines.join
        @build_errors = stderr.readlines.join
      end
  	@result_filename = File.join(build_dir, "bin", "sofia.micro.wombats.apk")
  # 	FileUtils.cp_r(result_filename, File.join(public_folder, result_filename))
  end
  #empty version of project.greenfoot 

  
  # ---------------------------------------------------------------
  # Checks to see if a zip file has a single directory at its root. If so, the
  # name of that directory is returned; otherwise, nil is returned.
  def dir_at_zip_root(file)
    last_prefix = nil

    Zip::ZipFile.open(file) do |zip_file|
      zip_file.each do |entry|
        slash = entry.name.index('/')

        if slash
          this_prefix = entry.name[0..slash]
          
          if last_prefix && this_prefix != last_prefix
            return nil
          end

          last_prefix = this_prefix
        else
          return nil
        end
      end

      if last_prefix
        last_prefix[0..last_prefix.length - 1]
      else
        nil
      end
    end
  end


  # ---------------------------------------------------------------
  # Unzips a file. If the file has a single directory at its root, then the
  # contents of that directory are extracted; otherwise, the zip file is
  # extracted as-is. This is necessary since some zip tools might package
  # things in a top-level directory and we need things like the "src"
  # folders extracted directly in the place where we tell it.
  def unzip_file(file, destination)
    root_dir = dir_at_zip_root(file)

    Zip::ZipFile.open(file) do |zip_file|
      zip_file.each do |entry|
        if root_dir
          name = entry.name[root_dir.length .. entry.name.length]
        else
          name = entry.name
        end

        entry_dest = File.join(destination, name)
        FileUtils.mkdir_p File.dirname(entry_dest)
        zip_file.extract entry, entry_dest unless File.exist?(entry_dest)
      end
    end
  end


  # ---------------------------------------------------------------
  # Copies a master project into the build area for a student. If the master
  # project contains files that the student also created, they will be
  # overwritten (maybe we need to ignore these?)
  def merge_master_project(destination)
    # Weird . path is required to copy contents of directory instead of
    # directory itself.
    master_dir = "masters/wombats/."
 
    #copies the contents of master_dir to the destination directory
    FileUtils.cp_r master_dir, destination

    # Generate a local.properties file with the correct SDK path.
    File.open("#{destination}/local.properties", 'w') do |f|
      f.write "sdk.dir=#{settings.android_sdk_path}"
    end
  end


  # ---------------------------------------------------------------
  # Recursively checks the directory for .java files and temporarily 
  # places them in a temporary directory 
  def find_src_files(dir, pid)
  	temp_dir = File.join(Dir.pwd, dir, "tmp")
  	FileUtils.mkdir_p temp_dir
  	Find.find(dir) do |f|
   		if f.match(/\.java\Z/)
  			path = File.join(Dir.pwd, "#{f}")
  			basename = File.basename(f, ".java")
  			target_dir = File.join(temp_dir, "#{basename}.java")

  			if (!File.exist?(target_dir))
  				FileUtils.mkdir_p File.dirname(target_dir)
  				FileUtils.cp_r(path, target_dir) unless File.exist?(target_dir)
  			end
  		end
  	end
  end


  # ---------------------------------------------------------------
  # Moves the src files placed in the temporary directory to src/sofia/micro/wombats
  # Calls helper methods to edit package declaration in the .java  files
  def merge_src_files(dir, pid)
  	src_dir = File.join(Dir.pwd, dir, "src", "sofia", "micro", "wombats");
  	FileUtils.rm_rf(File.join(Dir.pwd, dir, "src"))
  	FileUtils.mkdir_p File.join(src_dir)
  	Find.find(dir) do |f|
    	if f.match(/\.java\Z/)
  			path = File.join(Dir.pwd, "#{f}")
  			edit_package_name(path)
  			basename = File.basename(f, ".java")
  			target_dir = File.join(src_dir, "#{basename}.java")
  			if (!File.exist?(target_dir))
  				FileUtils.mkdir_p File.dirname(target_dir)
  				FileUtils.cp_r(path, target_dir)
  			end
  		end
  	end
  end


  # ---------------------------------------------------------------
  # Edits the given file to change package declaration to be in the 
  # appropriate place.
  def edit_package_name(file_path)
  	tmp = Tempfile.new("extract")

  	# Write good lines to temporary file
  	open(file_path, 'r').each do |l|
      tmp << l unless l.chomp == 'package sofia.micro.wombats;'
    end
  	# Close tmp, or troubles ahead
  	tmp.close
  	# Move temp file to origin
  	FileUtils.mv(tmp.path, file_path)
  	newline = 'package sofia.micro.wombats;'
    File.open(file_path, 'w+') do |f1|
      f1.write(newline)
    end
  end
 
end
