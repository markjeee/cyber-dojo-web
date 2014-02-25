
require 'TimeBoxedTask'

class Sandbox

  def initialize(avatar)
    @disk = Thread.current[:disk] || fatal("no disk")
    @git  = Thread.current[:git]  || fatal("no git")
    @task = Thread.current[:task] || TimeBoxedTask.new
    @avatar = avatar
  end

  def dir
    @disk[path]
  end

  def path
    @avatar.path + 'sandbox' + @disk.dir_separator
  end

  def test(delta, visible_files, max_duration = 15)
    delta[:changed].each do |filename|
      dir.write(filename, visible_files[filename])
    end
    delta[:new].each do |filename|
      dir.write(filename, visible_files[filename])
      @git.add(path, filename)
    end
    delta[:deleted].each do |filename|
      @git.rm(path, filename)
    end
    command  = "cd '#{path}';" +
               "./cyber-dojo.sh"
    output = @task.execute(command, max_duration)
    # create output file so it appears in diff-view
    dir.write('output', output)
    output.encode('utf-8', 'binary', :invalid => :replace, :undef => :replace)
  end

private

  def fatal(diagnostic)
    raise diagnostic
  end

end
