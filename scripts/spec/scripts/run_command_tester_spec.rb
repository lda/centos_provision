require 'spec_helper'

RSpec.describe 'test-run-command.sh' do
  include_context 'run script in tmp dir'
  include_context 'build subject'

  SUCCESS_EXIT_CODE = 0
  ERROR_EXIT_CODE = 1

  let(:script_name) { 'test-run-command.sh' }
  let(:message) {}
  let(:hide_output) {}
  let(:allow_errors) {}
  let(:run_as) {}
  let(:fail_message_builder) {}
  let(:helper_scripts_path) { "#{File.dirname(File.expand_path(__FILE__, '../'))}/run_command_tester" }
  let(:args) { "'#{helper_scripts_path}/#{helper_script}' '#{message}' '#{hide_output}' '#{allow_errors}' '#{run_as}' '#{fail_message_builder}'" }

  describe 'test standard failing filter' do
    let(:print_sh_counter) { 30 }
    let(:print_sh_exit_code) {}
    let(:helper_script) { "print.sh #{print_sh_counter} #{print_sh_exit_code}" }

    shared_examples_for 'prints lines to' do |destination|
      it_behaves_like 'should print to', destination, [
        'output 0',
        'error 0',
        'output 29',
        'error 29',
      ]
    end

    context 'successful command run' do
      let(:print_sh_exit_code) { SUCCESS_EXIT_CODE }

      it_behaves_like 'prints lines to', :log
      it_behaves_like 'prints lines to', :stdout

      context 'hide_output specified' do
        let(:message) { 'Running print command' }
        let(:hide_output) { true }

        it_behaves_like 'prints lines to', :log
        it_behaves_like 'should print to', :stdout, 'Running print command . OK'
        it_behaves_like 'should not print to', :stdout, ['error 0', 'error 29', 'output 0', 'output 29']
      end
    end

    context 'failed command run' do
      let(:print_sh_exit_code) { ERROR_EXIT_CODE }

      it_behaves_like 'prints lines to', :log
      it_behaves_like 'prints lines to', :stdout

      describe 'should print last 20 lines of command stderr/stdout' do
        it_behaves_like 'should print to', :stderr, ['error 10', 'error 29', 'output 10', 'output 29']
        it_behaves_like 'should not print to', :stderr, ['error 0', 'error 9', 'output 0', 'output 9']
      end
    end
  end

  describe 'test ansible_failure' do
    let(:scenario_path) { "#{helper_scripts_path}/ansible/#{scenario}" }
    let(:helper_script) { "cat_files.sh #{scenario_path}/output #{scenario_path}/error #{ERROR_EXIT_CODE}" }
    let(:fail_message_builder) { 'print_ansible_fail_message' }

    context 'install keitaro' do
      let(:scenario) { 'install_keitaro' }

      # it_behaves_like 'should print to', :stderr, '[WARNING]: Ignoring "pattern" as it is not used in "systemd"'
      it_behaves_like 'should not print to', :stderr, 'TASK [keitaro : Install Keitaro TDS]'
      it_behaves_like 'should print to', :stderr, [
        "Ansible failed task: 'keitaro : Install Keitaro TDS'",
        'Ansible failed task path: /root/centos_provision-master/roles/keitaro/tasks/install.yml:7',
        #'Ansible task stderr is empty',
        #/Ansible task stdout:\n  Server Configuration(.*\n)+  Key is invalid.*/
      ]
    end
  end
end
