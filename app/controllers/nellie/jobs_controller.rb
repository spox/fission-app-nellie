class Nellie::JobsController < JobsController

  before_action do
    @valid_jobs = Job.dataset_with(
      :scalars => {
        :route => ['data', 'router', 'action'],
        :status => ['data', 'nellie', 'status']
      }
    ).where(
      :route => 'nellie',
      :account_id => current_user.run_state.current_account.id
    )
  end

  def details
    respond_to do |format|
      format.js do
        flash[:error] = 'Unsupported request!'
        javascript_redirect_to dashboard_path
      end
      format.html do
        @job = @valid_jobs.where(:message_id => params[:job_id]).first
        if(@job)
          @state = case @job.status
                   when :success
                     'success'
                   when :error
                     'danger'
                   else
                     'warn'
                   end
          @files = Smash.new.tap do |files|
            @job.payload.fetch(:data, :nellie, :history, []).each_with_index do |item, i|
              item.fetch(:logs, {}).each do |k,v|
                file = begin
                         Rails.application.config.fission_assets.get(v)
                       rescue Jackal::Assets::Error::NotFound
                         nil
                       end

                key = "#{k} <command #{i+1}>"
                files[key] = file ? file.read : "FILE NOT FOUND!"
              end
            end
          end
          if(log_key = @job.payload.get(:data, :nellie, :result, :log))
            @files["Log"] = Rails.application.config.fission_assets.get(log_key)
          end
        else
          flash[:error] = "Failed to locate requested job (ID: #{params[:job_id]})"
          redirect_to dashboard_path
        end
      end
    end
  end

end
