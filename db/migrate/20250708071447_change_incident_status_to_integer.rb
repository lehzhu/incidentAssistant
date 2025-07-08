class ChangeIncidentStatusToInteger < ActiveRecord::Migration[7.2]
  def up
    # First convert existing string values to integers
    execute <<-SQL
      UPDATE incidents SET status = 
        CASE 
          WHEN status = 'active' THEN '0'
          WHEN status = 'resolved' THEN '1'
          ELSE '0'
        END
    SQL
    
    # Remove default temporarily
    change_column_default :incidents, :status, nil
    
    # Then change the column type
    change_column :incidents, :status, :integer, using: 'status::integer'
    
    # Add back the default
    change_column_default :incidents, :status, 0
  end
  
  def down
    change_column :incidents, :status, :string, default: 'active'
  end
end
