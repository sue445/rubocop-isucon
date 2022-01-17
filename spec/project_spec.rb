# frozen_string_literal: true

RSpec.describe "rubocop-isucon project" do
  describe "config/default.yml" do
    default_config = YAML.load_file(root_dir.join("config", "default.yml"))

    describe "department config" do
      department_configs = default_config.select { |cop_name, _| cop_name.split("/").count == 2 }
      department_configs.each do |department_name, config|
        describe department_name do
          subject { config }

          its(["StyleGuideBaseURL"]) { should eq "https://sue445.github.io/rubocop-isucon/RuboCop/Cop/#{department_name}/" }
        end
      end
    end

    describe "cop config" do
      cop_configs = default_config.select { |cop_name, _| cop_name.split("/").count == 3 }
      cop_configs.each do |cop_name, config|
        describe cop_name do
          subject { config }

          let(:short_cop_name) { cop_name.split("/").last }

          its(["StyleGuide"]) { should eq "#{short_cop_name}.html" }
        end
      end
    end
  end
end
