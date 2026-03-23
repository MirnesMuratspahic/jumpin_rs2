using JumpIn.Models.SearchObjects;
using JumpIn.Services.BaseInterfaces;
using JumpIn.Services.Database;
using Mapster;

namespace JumpIn.Services.BaseServices
{
    public class BaseCRUDService<TModel, TSearch, TDbEntity, TInsert, TUpdate>
        : BaseService<TModel, TSearch, TDbEntity>, ICRUDService<TModel, TSearch, TInsert, TUpdate>
        where TSearch : BaseSearchObject
        where TDbEntity : class
    {
        public BaseCRUDService(JumpInDbContext context) : base(context) { }

        public virtual TModel Insert(TInsert request)
        {
            var entity = request.Adapt<TDbEntity>();

            BeforeInsert(request, entity);

            _context.Set<TDbEntity>().Add(entity);
            _context.SaveChanges();

            AfterInsert(request, entity);

            return entity.Adapt<TModel>();
        }

        public virtual TModel Update(int id, TUpdate request)
        {
            var entity = _context.Set<TDbEntity>().Find(id);

            if (entity == null)
                throw new Exception("Entity not found");

            if (entity is ISoftDeletable softDeletable && softDeletable.IsDeleted)
                throw new Exception("Entity not found");

            BeforeUpdate(request, entity);

            request.Adapt(entity);
            _context.SaveChanges();

            AfterUpdate(request, entity);

            return entity.Adapt<TModel>();
        }

        public virtual TModel Delete(int id)
        {
            var entity = _context.Set<TDbEntity>().Find(id);

            if (entity == null)
                throw new Exception("Entity not found");

            BeforeDelete(entity);

            if (entity is ISoftDeletable softDeletable)
            {
                softDeletable.IsDeleted = true;
                softDeletable.DeleteTime = DateTime.UtcNow;
            }
            else
            {
                _context.Set<TDbEntity>().Remove(entity);
            }

            _context.SaveChanges();

            AfterDelete(entity);

            return entity.Adapt<TModel>();
        }

        protected virtual void BeforeInsert(TInsert request, TDbEntity entity) { }
        protected virtual void AfterInsert(TInsert request, TDbEntity entity) { }
        protected virtual void BeforeUpdate(TUpdate request, TDbEntity entity) { }
        protected virtual void AfterUpdate(TUpdate request, TDbEntity entity) { }
        protected virtual void BeforeDelete(TDbEntity entity) { }
        protected virtual void AfterDelete(TDbEntity entity) { }
    }
}
