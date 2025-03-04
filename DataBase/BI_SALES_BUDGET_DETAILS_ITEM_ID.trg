CREATE OR ALTER trigger bi_sales_budget_details_item_id for sales_budget_details
active before update position 0
AS
BEGIN
    -- Obtém o próximo valor do gerador
    NEW.ID_SALE_BUDGET_ITEM = GEN_ID(GEN_ID_SALE_BUDGET_ITEM, 1);
END
