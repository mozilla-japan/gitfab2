json.html (render 'components/card',
                  card: @annotation,
                  parent: @state,
                  delete_url: project_recipe_state_annotation_path(
                    owner_name: @owner.slug,
                    project_id: @project.name,
                    state_id: @state.id,
                    id: @annotation.id),
                  edit_url: edit_project_recipe_state_annotation_path(
                    owner_name: @owner.slug,
                    project_id: @project.name,
                    state_id: @state.id,
                    id: @annotation.id))
