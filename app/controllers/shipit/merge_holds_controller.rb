# frozen_string_literal: true

module Shipit
  class MergeHoldsController < ShipitController
    before_action :load_stack, except: %i[global_index]

    def index
      @merge_holds = @stack.merge_holds.ordered
    end

    def new
      @merge_hold = @stack.merge_holds.build
    end

    def show
      @merge_hold = @stack.merge_holds.find(params[:id])
    end

    def create
      @merge_hold = @stack.merge_holds.build(merge_hold_params)
      @merge_hold.author = current_user
      if @merge_hold.save
        flash[:success] = "Merge hold created"
        redirect_to(stack_merge_holds_path(@stack))
      else
        flash.now[:warning] = "Check form for errors"
        render(:new, status: :unprocessable_entity)
      end
    end

    def revoke
      @merge_hold = @stack.merge_holds.find(params[:id])
      if @merge_hold.revoke!(current_user)
        flash[:success] = "Merge hold revoked"
      else
        flash[:warning] = "Could not revoke merge hold"
      end
      redirect_to(stack_merge_holds_path(@stack))
    end

    def global_index
      @merge_holds = MergeHold.active.includes(:stack, :author).ordered
    end

    private

    def load_stack
      @stack = Stack.from_param!(params[:stack_id] || params[:id])
    end

    def merge_hold_params
      permitted = params.require(:merge_hold).permit(:reason, :starts_at, :ends_at, :exempt_github_logins)
      permitted[:starts_at] = nil if permitted[:starts_at].blank?
      permitted[:ends_at] = nil if permitted[:ends_at].blank?
      permitted
    end
  end
end
