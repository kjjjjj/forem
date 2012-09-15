class Vote < ActiveRecord::Base

  scope :for_voter, lambda { |*args| where(["voter_id = ? AND voter_type = ?", args.first.id, args.first.class.base_class.name]) }
  scope :for_voteable, lambda { |*args| where(["voteable_id = ? AND voteable_type = ?", args.first.id, args.first.class.base_class.name]) }
  scope :recent, lambda { |*args| where(["created_at > ?", (args.first || 2.weeks.ago)]) }
  scope :descending, order("created_at DESC")

  belongs_to :voteable, :polymorphic => true
  belongs_to :voter, :polymorphic => true

  attr_accessible :vote, :voter, :voteable


  # Comment out the line below to allow multiple votes per user.
  validates_uniqueness_of :voteable_id, :scope => [:voteable_type, :voter_type, :voter_id]

  after_save :update_activity_stream

  private
    def ensure_vote_event_exclusiveness
      options = {
        :author_user_id => voter.id,
        :event_type => self.class.to_s,
        :topic_id => voteable.id
      }
      existing_event_for_this_topic = TimelineEvent.where(options).first
      if existing_event_for_this_topic.present?
        Rails.logger.debug "Remove previous vote event for this user for this topic"
        existing_event_for_this_topic.destroy
      end
    end

    def update_activity_stream
      ensure_vote_event_exclusiveness
      create_options = {
        :author_user_id => voter.id,
        :event_type => self.class.to_s,
        :vote_id => id,
        :topic_id => voteable.id
      }
      TimelineEvent.create!(create_options)
    end
end
