module TaskManager
  module TrackerPath
      extend ActiveSupport::Concern
          included do
              unloadable

              # __________ТРЕКЕРЫ__________
              INITIATIVE_TRACKER_ID = 30 # - инициатива
              REQUIREMENT_TRACKER_ID = 31 # - требования
              ANALYSIS_TRACKER_ID = 26

              def is_requirement?
                  self.id == REQUIREMENT_TRACKER_ID
              end

              def is_analysis?
                self.id == ANALYSIS_TRACKER_ID
              end



              def is_initiative?
                  self.id ==  INITIATIVE_TRACKER_ID
              end


      end
  end
end

require_dependency 'issue'

module TaskManager
  module IssuePath
    def self.included(base)
      base.class_eval do
        before_save :check_child_analysis_status

        def check_child_analysis_status
          if tracker && status_id == INWORK_STATUS_ID && parent.present? && parent.tracker_id == INITIATIVE_TRACKER_ID
            parent.status_id = ANALYSIS_STATUS_ID
            # здесь нужно вставить аналитика с Анализа на Родительскую задачу
            parent.assigned_to = self.assigned_to if self.assigned_to
            parent.save!
          end
        end






      end
    end
  end
end



require_dependency 'issue'
module TaskManager
  module IssueStatusPath
      extend ActiveSupport::Concern
          included do
              unloadable

              INWORK_STATUS_ID == 59 # Статус в работе
              ANALYSIS_STATUS_ID == 84 # Статус анализ





      end
  end
end



require 'redmine'

Issue.send(:include, TaskManager::IssuePath)
Tracker.send(:include, TaskManager::TrackerPath)
IssueStatus.send(:include, TaskManager::IssueStatusPath)

Redmine::Plugin.register :task_manager do
  name 'Task Manager plugin'
  author 'Volchkov Nikolay'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'


require_dependency 'issue'
require_relative 'lib/task_manager/issue_path'

# Засовываю в общий список модулей(для вкл\выкл в настройках проекта)
  project_module :task_manager do
    permission :use_task_manager, {}
  end
end


Статусы.
Механика:
1)	После согласования инициативы, она должна перейти в статус Новая
2)	При отсутствии согласования Инициатива закрывается???(или перемещения на другого заказчика)
3)	Когда дочерняя задача Инициативы с трекером “Анализ” переходит в статус “В работе”, проставляется ответственный аналитик по Инициативе и у нее меняется статус на “Анализ”.
4)	После того, когда все подзадачи переведены в статус “Выполнено”, то Инициатива переходит в статус “Приёмка”
5)	!(необязательно) Если у инициативы статус “Приёмка” и в комментариях написать слово “Закрыта”, то Инициатива переходит в статус “Закрыта”.
6)	Если Инициатива переводится в статус “Новая” и у нее есть подзадача с трекером Анализ и статусом “В работе”, то Анализ тоже переводится в “Новая”.
7)	Если Инициатива пробыла в статусе “В ожидании” больше 3-х месяцев, то Инициатива меняет статус на “Анализ”.
8)	Если Инициатива находится в статусе “Разработка”, а после переходит в статус “Бэклог”, то подзадачи с трекерами “Пользовательская история” и “Технологический долг” переходят в статус Новая.
9)	Если трекер не Инициатива, и подзадача переводится в статус “В работе”, то и сама задача переводится в статус “В работе”.
10)	Если у всех подзадач статус “Закрыта”,

Трекеры.
Механика:
1)	К трекеру Цель может быть связаны только: Инициатива, User Story, Ошибка, Технический долг, Улучшение.
2) Также реализовано все по таблице:
Трекеры задач:
№	Трекер	Назначение	Наличие родителя	Наличие подчиненых задач
1	Цель	Стратегическая цели, цели продукта или цели подразделения	Нет	Да
2	Инициатива	Идея или новый функционал, которые направлены на развитие, достижение стратегических целей или целей подразделения	Нет	Да
3	Пользовательская история (User Story)	Новый функционал или изменение существующего функционала, который возможно реализовать за спринт и после выполнения принесет реальную ценность для бизнеса, продукта или пользователя	Возможно	Да
4	Ошибка	Задача на устранение несоответствия ранее реализованного функционала требованиям, требующая доработки систем или ПО	Возможно	Да
5	Технический долг	Задача на развитие технического или технологического качеств продукта, которая позволит повысить отказоустойчивость, быстродействий и/или стабильность работы	Возможно	Да
6	Улучшение	Задача на развитие процессов команды	Возможно	Да
7	Анализ	1. Сбор требований, изучение документации или аналогичных решений для проектирования решения
2. Формирование архитектурного решения, карты пользовательских сценариев и списка пользовательских сценариев для реализации	Да	Да
8	Инфраструктура	Задача для отслеживания изменений в инфраструктуре для реализации нового функционала (покупка и настройка оборудования, изменение настроек инфраструктуры и др.)	Да	Нет

Трекеры подзадач:
9	Анализ ПЗ	Уточнение требований и формирование сценария работы (Use Case) или технического задания	Да	Нет
10	Разработка ПЗ	1. Разработка функционала в соответствии с требованиям
2. Настройка функционала в соответствии с требованиями без разработки 3. Код-ревью	Да	Нет
11	Тестирование ПЗ	1. Разработка тестовых сценариев 
2. Подготовка тестовых кейсов 
3. Функциональное тестирование 
4. Автоматизация тестирования
5. Приемочное тестирование заказчиком	Да	Нет
12	Документирование ПЗ	1. Формирование технической документации по новому функционалу для передачи на сопровождение
2. Подготовка краткой инструкции для пользователей
3. Актуализация внутренней документации по системе или ПО	Да	Нет
13	Ошибка ПЗ	Задача на устранение несоответствия ранее реализованного функционала требованиям, требующая доработки систем или ПО	Да	Нет
14	Инфраструктура ПЗ	Задача для отслеживания изменений в инфраструктуре для реализации нового функционала (покупка и настройка оборудования, изменение настроек инфраструктуры и др.)	Да	Нет







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
