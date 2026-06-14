namespace JumpIn.Services.BaseInterfaces
{
    public interface ICRUDService<TModel, TSearch, TInsert, TUpdate> : IService<TModel, TSearch>
    {
        TModel Insert(TInsert request);
        TModel Update(Guid id, TUpdate request);
        TModel Delete(Guid id);
    }
}
