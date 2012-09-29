module Forem
  class Subscription < ActiveRecord::Base
    belongs_to :topic
    belongs_to :subscriber, :class_name => Forem.user_class.to_s

    validates :subscriber_id, :presence => true

    attr_accessible :subscriber_id

    def send_notification(post_id)
      ::TopicSubscriptionMailer.topic_reply(post_id, subscriber.id)
    end
  end
end
