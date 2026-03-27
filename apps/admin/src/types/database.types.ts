export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never;
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      graphql: {
        Args: {
          extensions?: Json;
          operationName?: string;
          query?: string;
          variables?: Json;
        };
        Returns: Json;
      };
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
  public: {
    Tables: {
      addresses: {
        Row: {
          city: string;
          country: string;
          created_at: string;
          customer_id: string;
          id: string;
          is_active: boolean;
          is_default: boolean;
          label: string | null;
          notes: string | null;
          postal_code: string;
          state: string | null;
          street: string;
          tenant_id: string;
          updated_at: string;
        };
        Insert: {
          city: string;
          country: string;
          created_at?: string;
          customer_id: string;
          id?: string;
          is_active?: boolean;
          is_default?: boolean;
          label?: string | null;
          notes?: string | null;
          postal_code: string;
          state?: string | null;
          street: string;
          tenant_id: string;
          updated_at?: string;
        };
        Update: {
          city?: string;
          country?: string;
          created_at?: string;
          customer_id?: string;
          id?: string;
          is_active?: boolean;
          is_default?: boolean;
          label?: string | null;
          notes?: string | null;
          postal_code?: string;
          state?: string | null;
          street?: string;
          tenant_id?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'addresses_customer_id_fkey';
            columns: ['customer_id'];
            isOneToOne: false;
            referencedRelation: 'customers';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'addresses_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      audit_logs: {
        Row: {
          action: Database['public']['Enums']['audit_action'];
          created_at: string;
          entity_id: string | null;
          entity_label: string | null;
          entity_type: string;
          id: string;
          ip_address: unknown;
          new_values: Json | null;
          notes: string | null;
          old_values: Json | null;
          staff_email: string | null;
          staff_id: string | null;
          staff_name: string | null;
          staff_role: string | null;
          tenant_id: string | null;
          tenant_name: string | null;
          user_agent: string | null;
        };
        Insert: {
          action: Database['public']['Enums']['audit_action'];
          created_at?: string;
          entity_id?: string | null;
          entity_label?: string | null;
          entity_type: string;
          id?: string;
          ip_address?: unknown;
          new_values?: Json | null;
          notes?: string | null;
          old_values?: Json | null;
          staff_email?: string | null;
          staff_id?: string | null;
          staff_name?: string | null;
          staff_role?: string | null;
          tenant_id?: string | null;
          tenant_name?: string | null;
          user_agent?: string | null;
        };
        Update: {
          action?: Database['public']['Enums']['audit_action'];
          created_at?: string;
          entity_id?: string | null;
          entity_label?: string | null;
          entity_type?: string;
          id?: string;
          ip_address?: unknown;
          new_values?: Json | null;
          notes?: string | null;
          old_values?: Json | null;
          staff_email?: string | null;
          staff_id?: string | null;
          staff_name?: string | null;
          staff_role?: string | null;
          tenant_id?: string | null;
          tenant_name?: string | null;
          user_agent?: string | null;
        };
        Relationships: [];
      };
      categories: {
        Row: {
          created_at: string;
          created_by: string | null;
          description: string | null;
          id: string;
          image_url: string | null;
          is_active: boolean;
          name: string;
          parent_id: string | null;
          slug: string;
          sort_order: number;
          tenant_id: string;
          updated_at: string;
        };
        Insert: {
          created_at?: string;
          created_by?: string | null;
          description?: string | null;
          id?: string;
          image_url?: string | null;
          is_active?: boolean;
          name: string;
          parent_id?: string | null;
          slug: string;
          sort_order?: number;
          tenant_id: string;
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          created_by?: string | null;
          description?: string | null;
          id?: string;
          image_url?: string | null;
          is_active?: boolean;
          name?: string;
          parent_id?: string | null;
          slug?: string;
          sort_order?: number;
          tenant_id?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'categories_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'categories_parent_id_fkey';
            columns: ['parent_id'];
            isOneToOne: false;
            referencedRelation: 'categories';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'categories_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      coupons: {
        Row: {
          code: string;
          created_at: string;
          created_by: string | null;
          description: string | null;
          discount_type: Database['public']['Enums']['discount_type'];
          discount_value: number;
          id: string;
          is_active: boolean;
          max_usage: number | null;
          min_order_amount: number | null;
          tenant_id: string;
          updated_at: string;
          usage_count: number;
          valid_from: string | null;
          valid_until: string | null;
        };
        Insert: {
          code: string;
          created_at?: string;
          created_by?: string | null;
          description?: string | null;
          discount_type: Database['public']['Enums']['discount_type'];
          discount_value: number;
          id?: string;
          is_active?: boolean;
          max_usage?: number | null;
          min_order_amount?: number | null;
          tenant_id: string;
          updated_at?: string;
          usage_count?: number;
          valid_from?: string | null;
          valid_until?: string | null;
        };
        Update: {
          code?: string;
          created_at?: string;
          created_by?: string | null;
          description?: string | null;
          discount_type?: Database['public']['Enums']['discount_type'];
          discount_value?: number;
          id?: string;
          is_active?: boolean;
          max_usage?: number | null;
          min_order_amount?: number | null;
          tenant_id?: string;
          updated_at?: string;
          usage_count?: number;
          valid_from?: string | null;
          valid_until?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'coupons_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'coupons_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      customers: {
        Row: {
          avatar_url: string | null;
          created_at: string;
          created_by: string | null;
          email: string | null;
          first_name: string;
          gender: Database['public']['Enums']['customer_gender'] | null;
          id: string;
          is_active: boolean;
          last_name: string;
          notes: string | null;
          phone: string | null;
          source: Database['public']['Enums']['customer_source'];
          tenant_id: string;
          updated_at: string;
        };
        Insert: {
          avatar_url?: string | null;
          created_at?: string;
          created_by?: string | null;
          email?: string | null;
          first_name: string;
          gender?: Database['public']['Enums']['customer_gender'] | null;
          id?: string;
          is_active?: boolean;
          last_name: string;
          notes?: string | null;
          phone?: string | null;
          source?: Database['public']['Enums']['customer_source'];
          tenant_id: string;
          updated_at?: string;
        };
        Update: {
          avatar_url?: string | null;
          created_at?: string;
          created_by?: string | null;
          email?: string | null;
          first_name?: string;
          gender?: Database['public']['Enums']['customer_gender'] | null;
          id?: string;
          is_active?: boolean;
          last_name?: string;
          notes?: string | null;
          phone?: string | null;
          source?: Database['public']['Enums']['customer_source'];
          tenant_id?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'customers_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'customers_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      notifications: {
        Row: {
          created_at: string;
          entity_id: string | null;
          entity_label: string | null;
          entity_type: string | null;
          expires_at: string | null;
          id: string;
          is_dismissed: boolean;
          message: string;
          read_at: string | null;
          severity: Database['public']['Enums']['notification_severity'];
          staff_id: string | null;
          tenant_id: string;
          title: string;
          type: string;
        };
        Insert: {
          created_at?: string;
          entity_id?: string | null;
          entity_label?: string | null;
          entity_type?: string | null;
          expires_at?: string | null;
          id?: string;
          is_dismissed?: boolean;
          message: string;
          read_at?: string | null;
          severity?: Database['public']['Enums']['notification_severity'];
          staff_id?: string | null;
          tenant_id: string;
          title: string;
          type: string;
        };
        Update: {
          created_at?: string;
          entity_id?: string | null;
          entity_label?: string | null;
          entity_type?: string | null;
          expires_at?: string | null;
          id?: string;
          is_dismissed?: boolean;
          message?: string;
          read_at?: string | null;
          severity?: Database['public']['Enums']['notification_severity'];
          staff_id?: string | null;
          tenant_id?: string;
          title?: string;
          type?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'notifications_staff_id_fkey';
            columns: ['staff_id'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'notifications_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      order_items: {
        Row: {
          base_price: number;
          created_at: string;
          currency: string;
          discount_percentage: number;
          id: string;
          notes: string | null;
          order_id: string;
          product_id: string | null;
          product_name: string;
          quantity: number;
          row_total: number;
          sku: string | null;
          tenant_id: string;
          unit_price: number;
          variant_id: string | null;
          variant_name: string;
          variant_option: string;
        };
        Insert: {
          base_price: number;
          created_at?: string;
          currency?: string;
          discount_percentage?: number;
          id?: string;
          notes?: string | null;
          order_id: string;
          product_id?: string | null;
          product_name: string;
          quantity: number;
          row_total: number;
          sku?: string | null;
          tenant_id: string;
          unit_price: number;
          variant_id?: string | null;
          variant_name: string;
          variant_option: string;
        };
        Update: {
          base_price?: number;
          created_at?: string;
          currency?: string;
          discount_percentage?: number;
          id?: string;
          notes?: string | null;
          order_id?: string;
          product_id?: string | null;
          product_name?: string;
          quantity?: number;
          row_total?: number;
          sku?: string | null;
          tenant_id?: string;
          unit_price?: number;
          variant_id?: string | null;
          variant_name?: string;
          variant_option?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'order_items_order_id_fkey';
            columns: ['order_id'];
            isOneToOne: false;
            referencedRelation: 'orders';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'order_items_product_id_fkey';
            columns: ['product_id'];
            isOneToOne: false;
            referencedRelation: 'products';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'order_items_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'order_items_variant_id_fkey';
            columns: ['variant_id'];
            isOneToOne: false;
            referencedRelation: 'product_variants';
            referencedColumns: ['id'];
          },
        ];
      };
      orders: {
        Row: {
          cancelled_reason: string | null;
          coupon_code: string | null;
          coupon_discount: number;
          coupon_id: string | null;
          created_at: string;
          created_by: string | null;
          currency: string;
          customer_email: string | null;
          customer_id: string | null;
          customer_name: string;
          customer_phone: string | null;
          delivery_fee: number;
          grand_total: number;
          id: string;
          notes: string | null;
          order_number: string;
          payment_method: Database['public']['Enums']['payment_method'];
          payment_status: Database['public']['Enums']['payment_status'];
          shipping_city: string | null;
          shipping_country: string | null;
          shipping_notes: string | null;
          shipping_postal_code: string | null;
          shipping_state: string | null;
          shipping_street: string | null;
          source: Database['public']['Enums']['order_source'];
          status: Database['public']['Enums']['order_status'];
          subtotal: number;
          tenant_id: string;
          tracking_number: string | null;
          updated_at: string;
          vat_amount: number;
          vat_percentage: number;
        };
        Insert: {
          cancelled_reason?: string | null;
          coupon_code?: string | null;
          coupon_discount?: number;
          coupon_id?: string | null;
          created_at?: string;
          created_by?: string | null;
          currency?: string;
          customer_email?: string | null;
          customer_id?: string | null;
          customer_name: string;
          customer_phone?: string | null;
          delivery_fee?: number;
          grand_total: number;
          id?: string;
          notes?: string | null;
          order_number: string;
          payment_method: Database['public']['Enums']['payment_method'];
          payment_status?: Database['public']['Enums']['payment_status'];
          shipping_city?: string | null;
          shipping_country?: string | null;
          shipping_notes?: string | null;
          shipping_postal_code?: string | null;
          shipping_state?: string | null;
          shipping_street?: string | null;
          source?: Database['public']['Enums']['order_source'];
          status?: Database['public']['Enums']['order_status'];
          subtotal: number;
          tenant_id: string;
          tracking_number?: string | null;
          updated_at?: string;
          vat_amount?: number;
          vat_percentage?: number;
        };
        Update: {
          cancelled_reason?: string | null;
          coupon_code?: string | null;
          coupon_discount?: number;
          coupon_id?: string | null;
          created_at?: string;
          created_by?: string | null;
          currency?: string;
          customer_email?: string | null;
          customer_id?: string | null;
          customer_name?: string;
          customer_phone?: string | null;
          delivery_fee?: number;
          grand_total?: number;
          id?: string;
          notes?: string | null;
          order_number?: string;
          payment_method?: Database['public']['Enums']['payment_method'];
          payment_status?: Database['public']['Enums']['payment_status'];
          shipping_city?: string | null;
          shipping_country?: string | null;
          shipping_notes?: string | null;
          shipping_postal_code?: string | null;
          shipping_state?: string | null;
          shipping_street?: string | null;
          source?: Database['public']['Enums']['order_source'];
          status?: Database['public']['Enums']['order_status'];
          subtotal?: number;
          tenant_id?: string;
          tracking_number?: string | null;
          updated_at?: string;
          vat_amount?: number;
          vat_percentage?: number;
        };
        Relationships: [
          {
            foreignKeyName: 'orders_coupon_id_fkey';
            columns: ['coupon_id'];
            isOneToOne: false;
            referencedRelation: 'coupons';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'orders_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'orders_customer_id_fkey';
            columns: ['customer_id'];
            isOneToOne: false;
            referencedRelation: 'customers';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'orders_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      payments: {
        Row: {
          amount: number;
          attempt_number: number;
          created_at: string;
          currency: string;
          failure_reason: string | null;
          id: string;
          is_successful: boolean;
          notes: string | null;
          order_id: string;
          paid_at: string | null;
          payment_gateway: string | null;
          payment_method: Database['public']['Enums']['payment_method'];
          refund_reason: string | null;
          refunded_at: string | null;
          status: Database['public']['Enums']['payment_status'];
          tenant_id: string;
          transaction_ref: string | null;
          updated_at: string;
        };
        Insert: {
          amount: number;
          attempt_number?: number;
          created_at?: string;
          currency?: string;
          failure_reason?: string | null;
          id?: string;
          is_successful?: boolean;
          notes?: string | null;
          order_id: string;
          paid_at?: string | null;
          payment_gateway?: string | null;
          payment_method: Database['public']['Enums']['payment_method'];
          refund_reason?: string | null;
          refunded_at?: string | null;
          status?: Database['public']['Enums']['payment_status'];
          tenant_id: string;
          transaction_ref?: string | null;
          updated_at?: string;
        };
        Update: {
          amount?: number;
          attempt_number?: number;
          created_at?: string;
          currency?: string;
          failure_reason?: string | null;
          id?: string;
          is_successful?: boolean;
          notes?: string | null;
          order_id?: string;
          paid_at?: string | null;
          payment_gateway?: string | null;
          payment_method?: Database['public']['Enums']['payment_method'];
          refund_reason?: string | null;
          refunded_at?: string | null;
          status?: Database['public']['Enums']['payment_status'];
          tenant_id?: string;
          transaction_ref?: string | null;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'payments_order_id_fkey';
            columns: ['order_id'];
            isOneToOne: false;
            referencedRelation: 'orders';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'payments_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      product_images: {
        Row: {
          created_at: string;
          id: string;
          image_url: string;
          is_primary: boolean;
          product_id: string;
          sort_order: number;
          tenant_id: string;
        };
        Insert: {
          created_at?: string;
          id?: string;
          image_url: string;
          is_primary?: boolean;
          product_id: string;
          sort_order?: number;
          tenant_id: string;
        };
        Update: {
          created_at?: string;
          id?: string;
          image_url?: string;
          is_primary?: boolean;
          product_id?: string;
          sort_order?: number;
          tenant_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'product_images_product_id_fkey';
            columns: ['product_id'];
            isOneToOne: false;
            referencedRelation: 'products';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'product_images_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      product_variants: {
        Row: {
          actual_price: number | null;
          base_price: number;
          created_at: string;
          currency: string;
          discount_percentage: number;
          id: string;
          is_active: boolean;
          is_available: boolean;
          low_stock_threshold: number;
          name: string;
          option_name: string;
          product_id: string;
          sku: string | null;
          sort_order: number;
          stock_quantity: number;
          tenant_id: string;
          updated_at: string;
        };
        Insert: {
          actual_price?: number | null;
          base_price: number;
          created_at?: string;
          currency?: string;
          discount_percentage?: number;
          id?: string;
          is_active?: boolean;
          is_available?: boolean;
          low_stock_threshold?: number;
          name: string;
          option_name: string;
          product_id: string;
          sku?: string | null;
          sort_order?: number;
          stock_quantity?: number;
          tenant_id: string;
          updated_at?: string;
        };
        Update: {
          actual_price?: number | null;
          base_price?: number;
          created_at?: string;
          currency?: string;
          discount_percentage?: number;
          id?: string;
          is_active?: boolean;
          is_available?: boolean;
          low_stock_threshold?: number;
          name?: string;
          option_name?: string;
          product_id?: string;
          sku?: string | null;
          sort_order?: number;
          stock_quantity?: number;
          tenant_id?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'product_variants_product_id_fkey';
            columns: ['product_id'];
            isOneToOne: false;
            referencedRelation: 'products';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'product_variants_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      products: {
        Row: {
          category_id: string;
          created_at: string;
          created_by: string | null;
          description: string | null;
          id: string;
          max_order_quantity: number | null;
          name: string;
          slug: string;
          status: Database['public']['Enums']['product_status'];
          tags: string[] | null;
          tenant_id: string;
          updated_at: string;
          updated_by: string | null;
        };
        Insert: {
          category_id: string;
          created_at?: string;
          created_by?: string | null;
          description?: string | null;
          id?: string;
          max_order_quantity?: number | null;
          name: string;
          slug: string;
          status?: Database['public']['Enums']['product_status'];
          tags?: string[] | null;
          tenant_id: string;
          updated_at?: string;
          updated_by?: string | null;
        };
        Update: {
          category_id?: string;
          created_at?: string;
          created_by?: string | null;
          description?: string | null;
          id?: string;
          max_order_quantity?: number | null;
          name?: string;
          slug?: string;
          status?: Database['public']['Enums']['product_status'];
          tags?: string[] | null;
          tenant_id?: string;
          updated_at?: string;
          updated_by?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'products_category_id_fkey';
            columns: ['category_id'];
            isOneToOne: false;
            referencedRelation: 'categories';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'products_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'products_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'products_updated_by_fkey';
            columns: ['updated_by'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
        ];
      };
      staff_profiles: {
        Row: {
          avatar_url: string | null;
          created_at: string;
          created_by: string | null;
          email: string;
          first_name: string;
          id: string;
          is_active: boolean;
          last_name: string;
          phone: string | null;
          role: Database['public']['Enums']['staff_role'];
          tenant_id: string;
          updated_at: string;
        };
        Insert: {
          avatar_url?: string | null;
          created_at?: string;
          created_by?: string | null;
          email: string;
          first_name: string;
          id: string;
          is_active?: boolean;
          last_name: string;
          phone?: string | null;
          role?: Database['public']['Enums']['staff_role'];
          tenant_id: string;
          updated_at?: string;
        };
        Update: {
          avatar_url?: string | null;
          created_at?: string;
          created_by?: string | null;
          email?: string;
          first_name?: string;
          id?: string;
          is_active?: boolean;
          last_name?: string;
          phone?: string | null;
          role?: Database['public']['Enums']['staff_role'];
          tenant_id?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'staff_profiles_created_by_fkey';
            columns: ['created_by'];
            isOneToOne: false;
            referencedRelation: 'staff_profiles';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'staff_profiles_tenant_id_fkey';
            columns: ['tenant_id'];
            isOneToOne: false;
            referencedRelation: 'tenants';
            referencedColumns: ['id'];
          },
        ];
      };
      tenants: {
        Row: {
          created_at: string;
          id: string;
          is_active: boolean;
          name: string;
          owner_email: string;
          owner_phone: string | null;
          plan: Database['public']['Enums']['tenant_plan'];
          settings: Json;
          slug: string;
          trial_ends_at: string | null;
          updated_at: string;
        };
        Insert: {
          created_at?: string;
          id?: string;
          is_active?: boolean;
          name: string;
          owner_email: string;
          owner_phone?: string | null;
          plan?: Database['public']['Enums']['tenant_plan'];
          settings?: Json;
          slug: string;
          trial_ends_at?: string | null;
          updated_at?: string;
        };
        Update: {
          created_at?: string;
          id?: string;
          is_active?: boolean;
          name?: string;
          owner_email?: string;
          owner_phone?: string | null;
          plan?: Database['public']['Enums']['tenant_plan'];
          settings?: Json;
          slug?: string;
          trial_ends_at?: string | null;
          updated_at?: string;
        };
        Relationships: [];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      custom_jwt_claims: { Args: never; Returns: Json };
    };
    Enums: {
      audit_action:
        | 'created'
        | 'updated'
        | 'deleted'
        | 'enabled'
        | 'disabled'
        | 'login'
        | 'logout'
        | 'exported'
        | 'status_changed';
      customer_gender: 'male' | 'female' | 'other';
      customer_source: 'website' | 'phone' | 'walk_in' | 'admin_created';
      discount_type: 'percentage' | 'fixed_amount';
      notification_severity: 'info' | 'warning' | 'error';
      order_source: 'website' | 'phone' | 'walk_in' | 'admin_created';
      order_status:
        | 'pending'
        | 'preparing'
        | 'ready'
        | 'out_for_delivery'
        | 'completed'
        | 'cancelled';
      payment_method: 'card' | 'cash_on_delivery';
      payment_status: 'pending' | 'paid' | 'failed' | 'refunded';
      product_status: 'active' | 'out_of_stock' | 'disabled';
      staff_role: 'admin' | 'manager' | 'staff';
      tenant_plan: 'free' | 'starter' | 'pro';
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema['Tables'] & DefaultSchema['Views'])
    ? (DefaultSchema['Tables'] & DefaultSchema['Views'])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema['Tables']
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema['Tables']
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema['Enums']
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
    ? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema['CompositeTypes']
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
    ? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      audit_action: [
        'created',
        'updated',
        'deleted',
        'enabled',
        'disabled',
        'login',
        'logout',
        'exported',
        'status_changed',
      ],
      customer_gender: ['male', 'female', 'other'],
      customer_source: ['website', 'phone', 'walk_in', 'admin_created'],
      discount_type: ['percentage', 'fixed_amount'],
      notification_severity: ['info', 'warning', 'error'],
      order_source: ['website', 'phone', 'walk_in', 'admin_created'],
      order_status: ['pending', 'preparing', 'ready', 'out_for_delivery', 'completed', 'cancelled'],
      payment_method: ['card', 'cash_on_delivery'],
      payment_status: ['pending', 'paid', 'failed', 'refunded'],
      product_status: ['active', 'out_of_stock', 'disabled'],
      staff_role: ['admin', 'manager', 'staff'],
      tenant_plan: ['free', 'starter', 'pro'],
    },
  },
} as const;
