require_relative '../cyberdojo_test_base'
class AvatarTests < CyberDojoTestBase
  test 'deleted file is deleted from that repo tag' do
  test 'diff is not empty when change in files' do
    traffic_lights = avatar.lights.each.entries
  test 'diff shows added file' do
  test 'diff shows deleted file' do
  test 'output is correct on refresh' do