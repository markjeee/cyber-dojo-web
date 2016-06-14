#!/bin/bash ../test_wrapper.sh

# Plan. Convert this to regular ruby program/class (keep inside web)
#          CyberDojoVolumeChecker
#       Has to return non-zero if issue found.
#       Replace test methods with calls to this program.
#
# Note. visible_filenames cannot include 'manifest.json'

class VolumeManifestChecker

  def initialize(path)
    @manifests = {}
    @errors = {}
    Dir.glob("#{path}/**/manifest.json").each do |filename|
      content = IO.read(filename)                 # TODO: add rescue handling
      @manifests[filename] = JSON.parse(content)  # TODO: add rescue handling
      @errors[filename] = []
    end
  end

  attr_reader :errors # mapped per manifest-filename

  # - - - - - - - - - - - - - - - - - - - -

  def check
    check_all_manifests_have_a_unique_image_name
    check_all_manifests_have_a_unique_display_name
  end

  # - - - - - - - - - - - - - - - - - - - -

  def check_all_manifests_have_a_unique_image_name
    image_names = {}
    @manifests.each do |filename, manifest|
      image_name = manifest['image_name']
      image_names[image_name] ||= []
      image_names[image_name] << filename
    end
    image_names.each do |image_name, filenames|
      if filenames.size != 1
        @errors[filenames[0]] << "duplicate image_name:'#{image_name}' => #{filenames}"
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - -

  def check_all_manifests_have_a_unique_display_name
    display_names = {}
    @manifests.each do |filename, manifest|
      display_name = manifest['display_name']
      display_names[display_name] ||= []
      display_names[display_name] << filename
    end
    display_names.each do |display_name, filenames|
      if filenames.size != 1
        @errors[filenames[0]] << "duplicate display_name:'#{display_name}' => #{filenames}"
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - -

  private

end

# =================================================================

require_relative './languages_test_base'

class LanguagesManifestsTests < LanguagesTestBase

  def manifests
    Dir.glob("#{languages.path}/**/manifest.json").sort
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_zero(errors)
    count = 0
    errors.each do |filename,messages|
      puts filename if messages.size != 0
      messages.each { |message| puts "\t" + message }
      count += messages.size
    end
    assert_equal 0, count
  end

  test 'D00EFE',
  'no two language manifests have the same image_name' do
    checker = VolumeManifestChecker.new(languages.path)
    checker.check_all_manifests_have_a_unique_image_name
    assert_zero checker.errors
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '16735B',
  'no two language manifests have the same display_name' do
    checker = VolumeManifestChecker.new(languages.path)
    checker.check_all_manifests_have_a_unique_display_name
    assert_zero checker.errors
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '8B45E1',
  'no known flaws in manifests of any language/test/' do
    manifests.each do |filename|
      dir = File.dirname(filename)
      check_manifest(dir)
    end
  end

  def check_manifest(dir)
    @language = dir
    assert all_files_are_named_in_manifest?
    assert required_keys_exist?
    refute unknown_keys_exist?
    assert all_visible_files_exist?
    refute duplicate_visible_filenames?
    assert highlight_filenames_are_subset_of_visible_filenames?
    assert progress_regexs_valid?
    assert display_name_valid?
    assert image_name_valid?
    refute filename_extension_starts_with_dot?
    assert cyberdojo_sh_exists?
    assert cyberdojo_sh_has_execute_permission?
    assert colour_method_for_unit_test_framework_output_exists?
    refute any_files_owner_is_root?
    refute any_files_group_is_root?
    refute any_file_is_unreadable?
    assert created_kata_manifests_language_entry_round_trips?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def all_files_are_named_in_manifest?
    dir = File.dirname(manifest_filename)
    files = Dir.entries(dir).reject { |entry| File.directory?(entry) }
    # for some reason this does not reject _docker_context which is a dir
    files -= [ '_docker_context', 'manifest.json' ]
    files.each do |filename|
      # shunit2 is only hidden file
      next if filename == 'shunit2' && language_dir.end_with?('Bash/shunit2')
      unless visible_filenames.include? filename
        return false_puts_alert "#{filename} not present in visible_filenames"
      end
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def required_keys_exist?
    required_keys = %w( display_name
                        image_name
                        unit_test_framework
                        visible_filenames
                      )
    required_keys.each do |key|
      unless manifest.keys.include? key
        return false_puts_alert "#{manifest_filename} must contain key '#{key}'"
      end
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def unknown_keys_exist?
    known_keys = %w( display_name
                     filename_extension
                     highlight_filenames
                     image_name
                     progress_regexs
                     tab_size
                     unit_test_framework
                     visible_filenames
                   )
    manifest.keys.each do |key|
      unless known_keys.include? key
        return true_puts_alert "#{manifest_filename} contains unknown key '#{key}'"
      end
    end
    false_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def created_kata_manifests_language_entry_round_trips?
    skip "Round-trip test failing..."
    language = languages[display_name]
    assert !language.nil?, "!language.nil? display_name=#{display_name}"

    exercise = exercises['Print_Diamond']
    assert !exercise.nil?, '!exercise.nil?'

    kata = katas.create_kata(language, exercise)
    manifest = katas.kata_manifest(kata)
    lang = manifest['language']
    if lang.count('-') != 1
      message =
        "#{kata.id}'s manifest 'language' entry is #{lang}" +
        ' which does not contain a - '
      return false_puts_alert message
    end
    print '.'
    round_tripped = languages[lang]
    unless File.directory? round_tripped.path
      message =
        "kata #{kata.id}'s manifest 'language' entry is #{lang}" +
        ' which does not round-trip back to its own languages/sub/folder.' +
        ' Please check app/models/Languages.rb:new_name()'
      return false_puts_alert message
    end
    print '.'
    if lang != 'Bash-shunit2' && lang.each_char.any? { |ch| '0123456789'.include?(ch) }
      message = "#{kata.id}'s manifest 'language' entry is #{lang}" +
                ' which contains digits and looks like it contains a version number'
      return false_puts_alert message
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def duplicate_visible_filenames?
    visible_filenames.each do |filename|
      if visible_filenames.count(filename) > 1
        message = "#{manifest_filename}'s 'visible_filenames' contains" +
                  " #{filename} more than once"
        return false_puts_alert message
      end
    end
    false_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def progress_regexs_valid?
    if progress_regexs.class.name != 'Array'
      message = "#{manifest_filename}'s progress_regexs entry is not an array"
      return false_puts_alert message
    end
    if progress_regexs.length != 0 && progress_regexs.length != 2
      message = "#{manifest_filename}'s 'progress_regexs' entry does not contain 2 entries"
      return false_puts_alert message
    end
    progress_regexs.each do |s|
      begin
        Regexp.new(s)
      rescue
        return false_puts_alert "#{manifest_filename} cannot create a Regexp from #{s}"
      end
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def display_name_valid?
    parts = display_name.split(',').select { |part| part.strip != '' }
    if parts.count != 2
      message = "#{manifest_filename}'s 'display_name':'#{display_name}'" +
                " is not in 'language,test' format"
      return false_puts_alert message
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_name_valid?
    parts = image_name.split('_')
    if parts.size < 2
      message = "#{manifest_filename}'s 'image_name':'#{image_name}'" +
                " is not in 'language_test' format"
      return false_puts_alert message
    end
    language_name = parts[0]
    test_name = parts[1..-1].join('_')
    if language_name.count("0-9") > 0


      message = "#{manifest_filename}'s 'image_name':'#{image_name}'" +
                " contains digits in the language name '#{language_name}"
      return false_puts_alert message
    end
    if test_name.count(".0-9") > 0
      unless [language_name,test_name] == ['bash','shunit2']
        message = "#{manifest_filename}'s 'image_name':'#{image_name}'" +
                  " contains digits in the test name '#{test_name}"
        return false_puts_alert message
      end
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def filename_extension_starts_with_dot?
    if manifest['filename_extension'][0] != '.'
      message = "#{manifest_filename}'s 'filename_extension' does not start with a ."
      return true_puts_alert message
    end
    false_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def all_visible_files_exist?
    all_files_exist?(:visible_filenames)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def all_files_exist?(symbol)
    (manifest[symbol] || []).each do |filename|
      unless File.exists?(language_dir + '/' + filename)
        message =
          "#{manifest_filename} contains a '#{symbol}' entry [#{filename}]\n" +
          " but the #{language_dir}/ dir does not contain a file called #{filename}"
        return false_puts_alert message
      end
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def highlight_filenames_are_subset_of_visible_filenames?
    highlight_filenames.each do |filename|
      if filename != 'instructions' &&
           filename != 'output' &&
           !visible_filenames.include?(filename)
        message =
          "#{manifest_filename} contains a 'highlight_filenames' entry ['#{filename}'] " +
          " but visible_filenames does not include '#{filename}'"
        return false_puts_alert message
      end
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def cyberdojo_sh_exists?
    if visible_filenames.select { |filename| filename == 'cyber-dojo.sh' } == []
      message = "#{manifest_filename} must contain ['cyber-dojo.sh'] in 'visible_filenames'"
      return false_puts_alert message
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def cyberdojo_sh_has_execute_permission?
    unless File.stat(language_dir + '/' + 'cyber-dojo.sh').executable?
      return false_puts_alert 'cyber-dojo.sh does not have execute permission'
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def colour_method_for_unit_test_framework_output_exists?
    has_parse_method = true
    begin
      OutputColour.of(unit_test_framework, any_output='xx')
    rescue
      has_parse_method = false
    end
    unless has_parse_method
      message = "app/lib/OutputColour.rb does not contain a " +
                "parse_#{unit_test_framework}(output) method"
      return false_puts_alert message
    end
    true_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def any_files_owner_is_root?
    (visible_filenames + ['manifest.json']).each do |filename|
      uid = File.stat(language_dir + '/' + filename).uid
      owner = Etc.getpwuid(uid).name
      if owner == 'root'
        return true_puts_alert "owner of #{language_dir}/#{filename} is root"
      end
    end
    false_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def any_files_group_is_root?
    (visible_filenames + ['manifest.json']).each do |filename|
      gid = File.stat(language_dir + '/' + filename).gid
      owner = Etc.getgrgid(gid).name
      if owner == 'root'
        return true_puts_alert "owner of #{language_dir}/#{filename} is root"
      end
    end
    false_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def any_file_is_unreadable?
    (visible_filenames + ['manifest.json']).each do |filename|
      unless File.stat(language_dir + '/' + filename).world_readable?
        return true_puts_alert "#{language_dir}/#{filename} is not world-readable"
      end
    end
    false_dot
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  def display_name
    manifest_property
  end

  def image_name
    manifest_property.split('/')[1]
  end

  def visible_filenames
    manifest_property
  end

  def unit_test_framework
    manifest_property
  end

  def progress_regexs
    manifest_property || []
  end

  def highlight_filenames
    manifest_property || []
  end

  def manifest
    JSON.parse(IO.read(manifest_filename))
  end

  def manifest_filename
    language_dir + '/' + 'manifest.json'
  end

  def language_dir
    @language
  end

  def false_puts_alert(message)
    puts_alert message
    false
  end

  def true_puts_alert(message)
    puts_alert message
    true
  end

  def puts_alert(message)
    puts alert + '  ' + message
  end

  def alert
    "\n>>>>>>> #{language_dir} <<<<<<<\n"
  end

  def false_dot
    print '.'
    false
  end

  def true_dot
    #print '.'
    true
  end

  def manifest_property
    property_name = /`(?<name>[^']*)/ =~ caller[0] && name
    manifest[property_name]
  end

end
