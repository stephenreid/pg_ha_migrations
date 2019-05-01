require "spec_helper"

RSpec.describe PgHaMigrations::OutOfBandMigrator do
  describe "run" do
    it "prints instructions and waits for prompt" do
      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string).to match(/migrations_state/)
      expect(stdout.string).to match(/blocking_database_transactions/)
      expect(stdout.string).to match(/migrate /)
      expect(stdout.string).to match(/exit/)
    end

    it "responds to instructions command" do
      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "print instructions"
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string.scan(/print migrations_state/).size).to eq(2)
      expect(stdout.string.scan(/print instructions/).size).to eq(2)
      expect(stdout.string.scan(/print blocking_database_transactions/).size).to eq(2)
      expect(stdout.string.scan(/exit /).size).to eq(2)
    end

    it "always prints the migrations state" do
      run_migration

      allow(PgHaMigrations::UnrunMigrations).to receive(:_migration_files).with("_oob").and_return(
        [
          "db/migrate_oob/924201_release_9242_01.rb",
          "db/migrate_oob/924202_release_9242_01.rb",
          "db/migrate_oob/924203_release_9242_01.rb",
          "db/migrate_oob/924204_release_9242_01.rb",
          "db/migrate_oob/24000_release_240_00.rb",
        ]
      )

      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string).to match(/Out Of Band Migrations To Be Run/)
      expect(stdout.string).to match(/Unrun migrations:/)
      expect(stdout.string).to match(/924201/)
      expect(stdout.string).to match(/924202/)
      expect(stdout.string).to match(/924203/)
      expect(stdout.string).to match(/924204/)
    end

    it "responds to migrations_state command" do
      run_migration

      allow(PgHaMigrations::UnrunMigrations).to receive(:_migration_files).with("_oob").and_return(
        [
          "db/migrate_oob/924201_release_9242_01.rb",
          "db/migrate_oob/924202_release_9242_01.rb",
          "db/migrate_oob/924203_release_9242_01.rb",
          "db/migrate_oob/924204_release_9242_01.rb",
          "db/migrate_oob/24000_release_240_00.rb",
        ]
      )

      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "print migrations_state"
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string.scan(/Out Of Band Migrations To Be Run/).size).to eq(2)
      expect(stdout.string.scan(/Unrun migrations:/).size).to eq(2)
      expect(stdout.string.scan(/924201/).size).to eq(2)
      expect(stdout.string.scan(/924202/).size).to eq(2)
      expect(stdout.string.scan(/924203/).size).to eq(2)
      expect(stdout.string.scan(/924204/).size).to eq(2)
    end

    it "always prints blocking db transactions" do
      report = """
       Potentially blocking database transactions:
       Transaction 1
       Transaction 2
       Transaction 3
       Transaction 4
      """

      blocking_transactions = [1, 2, 3, 4]
      allow(PgHaMigrations::BlockingDatabaseTransactionsReporter).to receive(:get_blocking_transactions).and_return(blocking_transactions)
      allow(PgHaMigrations::BlockingDatabaseTransactionsReporter).to receive(:report).with(blocking_transactions).and_return(report)

      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string).to match(/Potentially blocking database transactions/)
      expect(stdout.string).to match(/Transaction 1/)
      expect(stdout.string).to match(/Transaction 2/)
      expect(stdout.string).to match(/Transaction 3/)
      expect(stdout.string).to match(/Transaction 4/)
    end

    it "responds to blocking_database_transactions" do
      report = """
       Potentially blocking database transactions:
       Transaction 1
       Transaction 2
       Transaction 3
       Transaction 4
      """

      blocking_transactions = [1, 2, 3, 4]
      allow(PgHaMigrations::BlockingDatabaseTransactionsReporter).to receive(:get_blocking_transactions).and_return(blocking_transactions)
      allow(PgHaMigrations::BlockingDatabaseTransactionsReporter).to receive(:report).with(blocking_transactions).and_return(report)

      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "print blocking_database_transactions"
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string.scan(/Potentially blocking database transactions/).size).to eq(2)
      expect(stdout.string.scan(/Transaction 1/).size).to eq(2)
      expect(stdout.string.scan(/Transaction 2/).size).to eq(2)
      expect(stdout.string.scan(/Transaction 3/).size).to eq(2)
      expect(stdout.string.scan(/Transaction 4/).size).to eq(2)
    end

    it "displays error for unknown print command" do
      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "print foo"
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string).to match(/Unknown command./)
    end

    it "displays error for unknown top level command" do
      stdin = StringIO.new
      stdout = StringIO.new
      stdin.puts "dosomething"
      stdin.puts "exit"
      stdin.rewind
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob", stdin, stdout)
      migrator.run

      expect(stdout.string).to match(/Unknown command./)
    end
  end

  describe "instructions" do
    it "has instructions" do
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob")
      instructions = migrator.instructions
      expect(instructions).to match(/migrations_state/)
      expect(instructions).to match(/blocking_database_transactions/)
      expect(instructions).to match(/migrate/)
      expect(instructions).to match(/exit/)
    end
  end

  describe "migrations state" do
    it "includes the migration report" do
    end
  end

  describe "parse_command" do
    it "defaults to exit" do
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob")
      parsed = migrator.parse_command(nil)
      expect(parsed).to eq(["exit"])
    end

    it "splits commands" do
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob")
      parsed = migrator.parse_command("print blocking_database_transactions")
      expect(parsed).to eq(["print", "blocking_database_transactions"])
    end
  end

  describe "should_exit?" do
    it "is truthy for 'exit'" do
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob")
      expect(migrator.should_exit?("exit")).to be_truthy
    end

    it "is falsey for everything else" do
      migrator = PgHaMigrations::OutOfBandMigrator.new("_oob")
      expect(migrator.should_exit?("print foo")).to be_falsey
    end
  end

  def run_migration
    migration = Class.new(ActiveRecord::Migration::Current) do
      def up
        safe_create_table :foos1 do |t|
          t.timestamps :null => false
          t.text :text_column
        end
        safe_create_table :foos2 do |t|
          t.timestamps :null => false
          t.text :text_column
        end
      end
    end

    migration.version = 24000
    migration.name = "240_00"

    migration.suppress_messages do
      ActiveRecord::Migrator.new(:up, [migration]).migrate
    end
  end
end
