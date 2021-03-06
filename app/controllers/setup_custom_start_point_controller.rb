
class SetupCustomStartPointController < ApplicationController

  # Custom exercise (one-step setup)

  def show
    @id = id
    @title = 'create'
    custom_names = display_names_of(dojo.custom)
    index = choose_language(custom_names, dojo.katas[id])
    @start_points = ::DisplayNamesSplitter.new(custom_names, index)
  end

  def pull_needed
    render json: { needed: !dojo.runner.pulled?(custom.image_name) }
  end

  def pull
    _output, exit_status = dojo.runner.pull(custom.image_name)
    render json: { succeeded: exit_status == 0 }
  end

  def save
    manifest = katas.create_kata_manifest(custom)
    kata = katas.create_kata_from_kata_manifest(manifest)
    render json: { id: kata.id }
  end

  private

  include StartPointChooser

  def display_names_of(start_points)
    start_points.map(&:display_name).sort
  end

  def custom
    dojo.custom[params['major'] + '-' + params['minor']]
  end

end
