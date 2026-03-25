# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name,        null: false
      t.text   :description
      t.string :status,      null: false, default: 'active'
      t.timestamps
    end
  end
end
