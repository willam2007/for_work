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
