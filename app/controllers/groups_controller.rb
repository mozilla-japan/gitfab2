class GroupsController < ApplicationController
  layout 'groups'

  def index
    @groups = current_user.groups.active
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    Group.transaction do
      @group.save!
      membership = current_user.join_to @group
      membership.role = 'admin'
      membership.save!
    end
    redirect_to edit_group_path(@group)
  rescue ActiveRecord::ActiveRecordError
    render :new
  end

  def edit
    @group = get_group(params[:id])
    unless can?(:edit, @group)
      render_403(layout: true)
    end
  end

  def update
    @group = get_group(params[:id])
    if can?(:update, @group)
      if @group.update(group_params)
        redirect_to edit_group_path(@group), notice: 'Group profile was successfully updated.'
      else
        render :edit
      end
    else
      render_403(layout: true)
    end
  end

  def destroy
    group = get_group(params[:id])
    if can?(:destroy, group)
      begin
        group.soft_destroy!
        redirect_to :groups
      rescue ActiveRecord::RecordNotSaved
        redirect_to edit_group_path(group), alert: 'Group was not deleted.'
      end
    else
      render_403(layout: true)
    end
  end

  private

    def group_params
      params.require(:group).permit(:name, :avatar, :avatar_cache, :url, :location)
    end

    def get_group(id)
      current_user.groups.active.friendly.find(id)
    end
end
