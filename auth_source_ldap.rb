namespace :sprints do
    desc 'Auto create global sprints'
    task :auto_create_global_sprints => :environment do
        desired_future_sprints = 3 # Количество будущих спринтов, которое должно быть всегда создано

        Project.where(use_global_sprint: true).find_each do |project|
            next if project.parent && project.parent.use_shared_sprint
              admin_user = User.find_by(admin: true)
              sprint_duration = 14 # Длительность спринта в днях
              today = Date.today

              future_sprints = Sprint.where(project_id: project)
                                   .where('sprint_start_date >= ?', today.beginning_of_week)
                                   .order(sprint_start_date: :asc)

              while future_sprints.count < desired_future_sprints
                  if future_sprints.any?
                      last_sprint = future_sprints.last
                      next_sprint_start_date = last_sprint.sprint_start_date + sprint_duration.days
                  else
                      next_sprint_start_date = today.beginning_of_week
                  end

                  sprint_start_date = next_sprint_start_date
                  sprint_end_date = sprint_start_date + (sprint_duration - 1).days

                  # Формируем название спринта
                  year = sprint_start_date.strftime('%y')
                  week_number = (sprint_start_date.strftime('%U').to_i / 2) + 1
                  sprint_name = "#{year}#{format('%02d', week_number)}"

                  # Определяем, является ли спринт общий
                  is_shared = project.use_shared_sprint


                  existing_sprint = Sprint.where(project_id: project, name: sprint_name).first
                  if existing_sprint
                    puts "Такой спринт #{sprint_name} #{project} уже существует"
                    next_sprint_start_date += sprint_duration.days
                    sprint_start_date = next_sprint_start_date
                    sprint_end_date = sprint_start_date + (sprint_duration - 1).days

                    year = sprint_start_date.strftime('%y')
                    week_number = (sprint_start_date.strftime('%U').to_i / 2) + 1
                    sprint_name = "#{year}#{format('%02d', week_number)}"

                    attempt_counter ||= 0
                    attempt_counter += 1
                    if attempt_counter > 4
                        break
                    end
                    existing_sprint = Sprint.where(project_id: project, name: sprint_name).first
                    if existing_sprint
                        puts "#{sprint_name}"
                        next
                    end
                end
                begin
                    # Создание спринта
                    Sprint.create!(
                        project_id: project.id,
                        name: sprint_name,
                        sprint_start_date: sprint_start_date,
                        sprint_end_date: sprint_end_date,
                        user_id: admin_user.id,
                        shared: is_shared
                    )
                  puts "Создан спринт #{sprint_name} для проекта #{project.name} #{' (общий)' if is_shared}"
                rescue => e
                    puts "Ошибка при создании спринта: #{e.message}"
                    break
                end
                  future_sprints = Sprint.where(project_id: project)
                                        .where('sprint_start_date >= ?', today.beginning_of_week)
                                        .order(sprint_start_date: :asc)
                end
            end
        end
end


<% if @issue.project != nil && @project != nil%>
  <% if @project.track_sprint_history && @issue.sprint_id != nil %>
  <p>
    <label for="move_reason_select">Причина смены спринта</label>
    <select id="move_reason_select" name="issue[move_reason_select]" onchange="toggleCustomReasonField(this)">
    <%= options_for_select(["Работы по задаче не завершены", "Работы по задаче не начаты", "Недостаточная оценка объема работ по задаче","Выполнение более приоритетной задачи", "Временная неработоспособность исполнителя (отпуск, больничный, пропал доступ)","Технические проблемы с релизом/перенос релиза","Недостаточный анализ выполняемой задачи (проблемы/вопросы, возникающие в ходе выполнения)","Ожидание ответа Заказчика","Согласование ТЗ или иных документов","Релиз задачи отложен Заказчиком", "Иное"],selected: @issue.move_reason)%>  
    </select>
    <textarea id="issue_move_reason" name="issue[move_reason]" placeholder = "Укажите причину" style = "display: none;" %></textarea>
  </p>
  <%end%>
<%end%>

<%= javascript_tag do %>
  function toggleCustomReasonField(selectElement) {
    var textField = document.getElementById('issue_move_reason');
    if (selectElement.value === 'Иное') {
      textField.style.display = '';
      textField.value = '';
    } else {
      textField.style.display = 'none';
      textField.value = selectElement.value;
    }
  }
  function toggleCustomReasonFieldReason(selectElement) {
    var textField = document.getElementById('issue_reason_waiting');
    if (selectElement.value === 'Иное') {
      textField.style.display = '';
      textField.value = '';
    } else {
      textField.style.display = 'none';
      textField.value = selectElement.value;
    }
  }

  document.addEventListener("DOMContentLoaded", function(){
    var selectElement = document.getElementById('issue_reason_waiting_select');
    toggleCustomReasonFieldReason(selectElement)
  });

  document.addEventListener("DOMContentLoaded", function(){
    var selectElement = document.getElementById('issue_move_reason_select');
    toggleCustomReasonField(selectElement)
  });

$(document).ready(function(){
  $("#issue_tracker_id, #issue_status_id").each(function(){
    $(this).val($(this).find("option[selected=selected]").val());
  });
  $(".assign-to-me-link").click(function(event){
    event.preventDefault();
    var element = $(event.target);
    $('#issue_assigned_to_id').val(element.data('id'));
    element.hide();
  });
  $('#issue_assigned_to_id').change(function(event){
    var assign_to_me_link = $(".assign-to-me-link");

    if (assign_to_me_link.length > 0) {
      var user_id = $(event.target).val();
      var current_user_id = assign_to_me_link.data('id');

      if (user_id == current_user_id) {
        assign_to_me_link.hide();
      } else {
        assign_to_me_link.show();
      }
    }
  });
});




-- ШАГ 1: Обновляем основную запись, ставим init_note = true
WITH duplicates AS (
  SELECT
    journalized_id,
    journalized_type,
    user_id,
    notes,
    created_on,
    private_notes,
    ARRAY_AGG(id ORDER BY init_note NULLS FIRST) AS ids
  FROM journals
  GROUP BY journalized_id, journalized_type, user_id, notes, created_on, private_notes
  HAVING COUNT(*) > 2
)
UPDATE journals
SET init_note = true
WHERE id IN (
  SELECT (ids[1])  -- первая запись в группе - основная
  FROM duplicates
);

-- ШАГ 2: Удаляем дубликаты
WITH duplicates AS (
  SELECT
    journalized_id,
    journalized_type,
    user_id,
    notes,
    created_on,
    private_notes,
    ARRAY_AGG(id ORDER BY init_note NULLS FIRST) AS ids
  FROM journals
  GROUP BY journalized_id, journalized_type, user_id, notes, created_on, private_notes
  HAVING COUNT(*) > 2
)
DELETE FROM journals
WHERE id IN (
  SELECT unnest(ids[2:])  -- остальные записи, начиная со второй, это дубликаты
  FROM duplicates
);



<div id="attributes" class="attributes">
  <%= render :partial => 'issues/attributes' %>
</div>
<!-- Поле причины ожидания -->
<p>
    <label>Причина ожидания</label>
    <select id="reason_waiting_select" name="issue[reason_waiting_select]" onchange="toggleCustomReasonFieldReason(this)">
    <%= options_for_select(["Ожидание ответа подрядчика", "Ожидание ответа заказчика", "Ожидание доработки в смежной системе/связанной задаче","Ожидает приобритения лицензии/оборудования", "Иное"],selected: @issue.reason_waiting)%>  
    </select>
    <textarea id="issue_reason_waiting" name="issue[reason_waiting]" placeholder = "Укажите причину" style = "display: none;" %></textarea>
</p>





namespace :sprints do
    desc 'Auto create global sprints'
    task :auto_create_global_sprints => :environment do
        desired_future_sprints = 3 # Количество будущих спринтов, которое должно быть всегда создано

        Project.where(use_global_sprint: true).find_each do |project|
            next if project.parent && project.parent.use_shared_sprint
              admin_user = User.find_by(admin: true)
              sprint_duration = 14 # Длительность спринта в днях
              today = Date.today

              future_sprints = Sprint.where(project_id: project)
                                   .where('sprint_start_date >= ?', today.beginning_of_week)
                                   .order(sprint_start_date: :asc)

              while future_sprints.count < desired_future_sprints
                  if future_sprints.any?
                      last_sprint = future_sprints.last
                      next_sprint_start_date = last_sprint.sprint_start_date + sprint_duration.days
                  else
                      next_sprint_start_date = today.beginning_of_week
                  end

                  sprint_start_date = next_sprint_start_date
                  sprint_end_date = sprint_start_date + (sprint_duration - 1).days

                  # Формируем название спринта
                  year = sprint_start_date.strftime('%y')
                  week_number = (sprint_start_date.strftime('%U').to_i / 2) + 1
                  sprint_name = "#{year}#{format('%02d', week_number)}"

                  # Определяем, является ли спринт общий
                  is_shared = project.use_shared_sprint


                  existing_sprint = Sprint.where(project_id: project,sprint_start_date: sprint_start_date).first
                  if existing_sprint
                    puts "Такой спринт #{sprint_name} уже существует"
                  else

                  begin
                  # Создание спринта
                    Sprint.create!(
                        project_id: project.id,
                        name: sprint_name,
                        sprint_start_date: sprint_start_date,
                        sprint_end_date: sprint_end_date,
                        user_id: admin_user.id,
                        shared: is_shared
                    )
                  puts "Создан спринт #{sprint_name} для проекта #{project.name} #{' (общий)' if is_shared}"
                  end
                  end
                  future_sprints = Sprint.where(project_id: project)
                                        .where('sprint_start_date >= ?', today.beginning_of_week)
                                        .order(sprint_start_date: :asc)
                end
            end
        end
end



 def sync_departments
    begin
      # Инициализируем соединение с LDAP
      ldap_con = initialize_ldap_con(self.account, self.account_password)
      division_filter = Net::LDAP::Filter.eq("objectClass", "organizationalUnit")
      # Поиск подразделений в LDAP
      ldap_entries = ldap_con.search(
        base: self.base_dn,
        filter: division_filter,
        # все уровни вложности
        scope: Net::LDAP::SearchScope_WholeSubtree,
        attributes: ['physicalDeliveryOfficeName','ou','name', 'distinguishedname']
      )
      if ldap_entries.nil? || ldap_entries.empty?
        return
      else
        Rails.logger.info "Search: #{ldap_entries.size}"
      end

      # Создаем хеш подразделений из LDAP
      ldap_departments = {}
      ldap_entries.each do |entry|
        department_code = AuthSourceLdap.get_attr(entry, 'physicalDeliveryOfficeName')
        name = AuthSourceLdap.get_attr(entry, 'ou')

        next unless department_code.present? && name.present?

        if ldap_departments.key?(department_code) || ldap_departments.key?(name)
          Rails.logger.warn "Double ldap_departments"
          next
        end
         clean_name = name.strip
         if clean_name[0] =~ /^\d/
           Rails.logger.warn "skip #{name}, beceause if numbers at the beginnning"
           next
         end


        ldap_departments[department_code] = {name: name, department_code: department_code, dn: entry.dn }
      end
      existing_departments = Department.all.index_by(&:department_code)
      ldap_department_codes = ldap_departments.keys

      # Синхронизация подразделений
      ldap_departments.each do |department_code, data|
        name = data[:name]
        department_code = data[:department_code]

        if existing_departments.key?(department_code)
          department = existing_departments[department_code]
          department.name = name
          department.background = "Sync from AD"
        else
          department = Department.new(
            name: name,
            department_code: department_code,
            background: "Add from AD"
          )
        end

        if department.save
          Rails.logger.info "Succefull save #{department.name}"
        else
          Rails.logger.error "Error save #{department.name}"
        end
      end

      # Удаляем подразделения, отсутствующие в LDAP
      departments_to_delete = existing_departments.keys - ldap_department_codes
      departments_to_delete.each do |department_code|
        department = existing_departments[department_code]
        department.destroy
        Rails.logger.info "Delete departments #{department.name}"
      end
      Rails.logger.info "END SYNC DEPARTMENTS"
    rescue => e
      Rails.logger.error "Warn in def sync_departments: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end

DN: OU=Отдел развития банковских технологий,OU=Основной офис,OU=Владивосток,OU=PSKB,DC=pskb,DC=ad
dn: ["OU=Отдел развития банковских технологий,OU=Основной офис,OU=Владивосток,OU=PSKB,DC=pskb,DC=ad"]
objectclass: ["top", "organizationalUnit"]
ou: ["Отдел развития банковских технологий"]
physicaldeliveryofficename: ["001-00-67"]
distinguishedname: ["OU=Отдел развития банковских технологий,OU=Основной офис,OU=Владивосток,OU=PSKB,DC=pskb,DC=ad"]
instancetype: ["4"]
whencreated: ["20220505050311.0Z"]
whenchanged: ["20220505051224.0Z"]
usncreated: ["86630857"]
usnchanged: ["86632356"]
name: ["Отдел развития банковских технологий"]
objectguid: ["\xA8F\x81i\x0F\x93\xC8B\xBF\xD5\x80\xD6\xCF\xC2Q\xDC"]
objectcategory: ["CN=Organizational-Unit,CN=Schema,CN=Configuration,DC=pskb,DC=ad"]
dscorepropagationdata: ["20240820071728.0Z", "20240820041136.0Z", "20240820014534.0Z", "20240820014403.0Z", "16010714223649.0Z"]
# RM {29466} (https://redmine.pskb.ad/issues/29466)
  # Атрибуты AD у подразделения:
  # id - идентификатор
  # physicalDeliveryOfficeName - имя
  # PSKBKodDivision - Код подразделения (числовое IBSO)
 DN: OU=Отдел развития банковских технологий,OU=Основной офис,OU=Владивосток,OU=PSKB,DC=pskb,DC=ad
I, [2024-11-18T11:39:38.989068 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] dn: ["OU=Отдел развития банковских технологий,OU=Основной офис,OU=Владивосток,OU=PSKB,DC=pskb,DC=ad"]
I, [2024-11-18T11:39:38.989097 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] objectclass: ["top", "organizationalUnit"]
I, [2024-11-18T11:39:38.989124 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] ou: ["Отдел развития банковских технологий"]
I, [2024-11-18T11:39:38.989151 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] physicaldeliveryofficename: ["001-00-67"]
I, [2024-11-18T11:39:38.989178 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] distinguishedname: ["OU=Отдел развития банковских технологий,OU=Основной офис,OU=Владивосток,OU=PSKB,DC=pskb,DC=ad"]
I, [2024-11-18T11:39:38.989204 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] instancetype: ["4"]
I, [2024-11-18T11:39:38.989230 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] whencreated: ["20220505050311.0Z"]
I, [2024-11-18T11:39:38.989256 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] whenchanged: ["20220505051224.0Z"]
I, [2024-11-18T11:39:38.989281 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] usncreated: ["86630857"]
I, [2024-11-18T11:39:38.989308 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] usnchanged: ["86632356"]
I, [2024-11-18T11:39:38.989335 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] name: ["Отдел развития банковских технологий"]
I, [2024-11-18T11:39:38.989362 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] objectguid: ["\xA8F\x81i\x0F\x93\xC8B\xBF\xD5\x80\xD6\xCF\xC2Q\xDC"]
I, [2024-11-18T11:39:38.989390 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] objectcategory: ["CN=Organizational-Unit,CN=Schema,CN=Configuration,DC=pskb,DC=ad"]
I, [2024-11-18T11:39:38.989417 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] dscorepropagationdata: ["20240820071728.0Z", "20240820041136.0Z", "20240820014534.0Z", "20240820014403.0Z", "16010714223649.0Z"]
I, [2024-11-18T11:39:38.989442 #24292]  INFO -- : [f5aa0716-cce3-436b-9816-b51e1af1d48f] ----------
  def sync_departments
    begin
      # Инициализируем соединение с LDAP
      ldap_con = initialize_ldap_con(self.account, self.account_password)
      division_filter = Net::LDAP::Filter.eq("objectClass", "*")
      # Поиск подразделений в LDAP
      ldap_entries = ldap_con.search(
        base: self.base_dn,
        filter: division_filter,
        attributes: ['physicalDeliveryOfficeName', 'PSKBKodDivision']
      )
      if ldap_entries.nil? || ldap_entries.empty?
        return
      else
        Rails.logger.info "Search: #{ldap_entries.size}"
      end

      # Создаем хеш подразделений из LDAP
      ldap_departments = {}
      ldap_entries.each do |entry|
        department_code = AuthSourceLdap.get_attr(entry, 'PSKBKodDivision')
        name = AuthSourceLdap.get_attr(entry, 'physicalDeliveryOfficeName')

        next unless department_code.present? && name.present?

        if ldap_departments.key?(department_code) || ldap_departments.key?(name)
          Rails.logger.warn "Double ldap_departments"
          next
        end
        clean_name = name.strip
        if clean_name[0] =~ /^\d/
          Rails.logger.warn "skip #{name}, beceause if numbers at the beginnning"
          next
        end


        ldap_departments[department_code] = {name: name, department_code: department_code, dn: entry.dn }
      end
      existing_departments = Department.all.index_by(&:department_code)
      ldap_department_codes = ldap_departments.keys

      # Синхронизация подразделений
      ldap_departments.each do |department_code, data|
        name = data[:name]
        department_code = data[:department_code]

        if existing_departments.key?(department_code)
          department = existing_departments[department_code]
          department.name = name
          department.background = "Sync from AD"
        else
          department = Department.new(
            name: name,
            department_code: department_code,
            background: "Add from AD"
          )
        end

        if department.save
          Rails.logger.info "Succefull save #{department.name}"
        else
          Rails.logger.error "Error save #{department.name}"
        end
      end

      # Удаляем подразделения, отсутствующие в LDAP
      departments_to_delete = existing_departments.keys - ldap_department_codes
      departments_to_delete.each do |department_code|
        department = existing_departments[department_code]
        department.destroy
        Rails.logger.info "Delete departments #{department.name}"
      end
      Rails.logger.info "END SYNC DEPARTMENTS"
    rescue => e
      Rails.logger.error "Warn in def sync_departments: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end
