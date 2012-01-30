namespace :rummager do
  desc "Reindex search engine"
  task :index => :environment do
    documents = [{
      "title"             => "When do the clocks change?",
      "description"       =>
        "In the UK the clocks go forward 1 hour at 1am on the last Sunday in "+
        "March, and back 1 hour at 2am on the last Sunday in October.",
      "format"            => "answer",
      "section"           => "life-in-the-uk",
      "subsection"        => "rights-and-citizenship",
      "link"              => "/when-do-the-clocks-change",
      "indexable_content" => %{
        This clock change gives the UK an extra hour of daylight (sometimes
        called Daylight Saving Time). From March to October (when the
        clocks are 1 hour ahead) the UK is on British Summer Time (BST).
        From October to March, the UK is on Greenwich Mean Time (GMT).
      }
    }, {
      "title"             => "UK bank holidays",
      "description"       => "UK bank holidays calendar - see UK bank holidays and public holidays for 2012 and 2013",
      "format"            => "answer",
      "section"           => "work",
      "subsection"        => "time-off",
      "link"              => "/bank-holidays",
      "indexable_content" => "",
    }]
    Rummageable.index documents
  end
end
