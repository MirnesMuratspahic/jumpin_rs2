namespace JumpIn.Services.BaseInterfaces
{
    public interface ICRUDService<TModel, TSearch, TInsert, TUpdate> : IService<TModel, TSearch>
    {
        TModel Insert(TInsert request);
        TModel Update(int id, TUpdate request);
        TModel Delete(int id);
    }
}
