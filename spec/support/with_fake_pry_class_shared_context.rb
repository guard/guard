RSpec.shared_context 'with fake_pry_class' do
  let(:fake_pry_class) do
    Class.new(Pry::Command) do
      def self.output; end
    end
  end
end
